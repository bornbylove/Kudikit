# CBA (Cyclos) Integration — Contract & Model Notes

> Reference for how the Kudikit app relates to the **Core Banking Application (CBA)**,
> which is [Cyclos](https://www.cyclos.org/) — the ledger engine holding wallet
> accounts, balances, and money movements.

## Topology — the app never talks to Cyclos directly

```
Flutter app ──Bearer JWT──▶  Kudikit backend  ──Basic auth──▶  Cyclos CBA
 (this repo)                 159.198.75.72:8086               199.192.22.72:8080
                            /api/v1/...                       /kudikit/api/... , /api/...
```

- The app authenticates **per-user** with a Bearer JWT (`_AuthInterceptor`, `lib/config/dio_client.dart`).
- Cyclos is reached with **master/admin Basic-auth credentials** (`kudikit_api`, `kudikit`).
  Those credentials must **never** ship in the mobile client — anyone could decompile the
  APK and move funds. Cyclos is a **server-to-server** dependency of the backend only.
- Therefore the backend is a **translation layer**: it must flatten Cyclos' response shapes
  into the shapes the app models below already expect. This doc pins down that contract.

`kBaseUrl` for the app lives in `lib/config/env.dart` (override with `--dart-define=API_URL=...`).

---

## Endpoint mapping — app ⟶ backend ⟶ Cyclos

| App feature (file) | App calls (backend) | Backend calls (Cyclos, from the collection) |
|---|---|---|
| Signup / register — `auth_services.dart` `signup()` | `POST /api/v1/auth/register` | `POST /kudikit/api/users` (group `tier_2_members`, name, username, phone, login password) |
| Tier upgrade — `tier/upgrade_tier_screen.dart`, `auth` `completeOnboarding()` | `POST /api/v1/auth/onboarding/complete` `{ tier }` | user `group` change (e.g. `tier1_member` → `tier_2_members`) |
| Wallet number + balance — `homescreen/home_screen.dart` | *(backend endpoint TBD — confirm)* | `GET /api/{user}/accounts/list-data` and `GET /api/{user}/accounts/{typeId}/balance-details` |
| Add money (card/Paystack credit) — `services/add_money_services.dart` | `POST /add-money/card/*` | `POST /api/kudikit/payments` `{ type: "fund_wallet", subject, amount }` **or** `POST /kudikit/api/system/payments` |
| Transaction history — `transaction/transaction_screen.dart`, `services/transaction_service.dart` | `GET /transactions` | `GET /api/{user}/transactions` |

> **Action:** confirm with backend which `/api/v1/...` route wraps `list-data` /
> `balance-details` — the app has no explicit wallet-balance service yet, so this is the
> most likely integration gap.

---

## Model gap analysis — Cyclos raw vs. what the app parses

The app's `fromJson` methods are **strict** (`as String`, `as num`). Cyclos returns
**stringified numbers** and **nested objects**. If the backend passes Cyclos shapes
through raw, the app throws at parse time. Each row states what the backend must return.

### 1. Transactions — `lib/model/transaction/transaction_model.dart`

`Transaction.fromJson` requires: `id:String`, `title|description:String`,
`date:String(ISO)`, `amount:num`, `status:String`, `type:String("debit"|"credit")`.

Cyclos `transaction-history` actually returns:

```json
{
  "id": "-388534538840336431",
  "date": "2026-06-12T14:00:39.125+01:00",
  "amount": "50000.00",                      // STRING, not number
  "type": { "internalName": "debit.toUser", "name": "Payment from Debit float account" },  // OBJECT, not string
  "description": "string",
  "kind": "payment",
  "creationType": "direct",
  "currency": "NGN",
  "related": { "type": { "internalName": "debit" }, "kind": "system" }
}
```

| App field | Cyclos source | Backend must transform |
|---|---|---|
| `amount` (num) | `"50000.00"` (string) | parse to number |
| `type` ("debit"/"credit") | `type.internalName` + `related.kind` | derive direction: crediting the member wallet ⇒ `credit`; debiting ⇒ `debit` |
| `status` | *(absent — Cyclos history has no status)* | inject `"successful"` for settled entries, or app model must tolerate a missing status |
| `title` | `type.name` or `description` | pass a human label, not the literal `"string"` |

> Without this mapping, `(json['amount'] as num)` and `json['status'] as String`
> both throw. Fix belongs in the **backend transform**, not by loosening the app model
> to match a ledger engine the app shouldn't know about.

### 2. Wallet account / balance — `lib/model/addmoney/addmoney.dart` `AccountDetails`

`AccountDetails` (`account_number`, `account_name`, `bank_name`) models a **virtual
funding account**, which is a *different concept* from the Cyclos wallet account.

Cyclos `list-data` returns the wallet:

```json
{
  "accounts": [{
    "number": "867550250",
    "status": {
      "balance": "150000.00",
      "availableBalance": "150000.00",
      "reservedAmount": "0.00",
      "creditLimit": "0.00",
      "upperCreditLimit": "300000.00"
    },
    "currency": { "internalName": "NGN", "symbol": "N", "decimalDigits": 2 }
  }]
}
```

- All monetary values are **strings** → backend must expose them as numbers (or the app
  needs a dedicated `WalletBalance` model that parses strings).
- `upperCreditLimit` (`300000.00`) is effectively the **tier limit** and should drive the
  tier UI (`lib/presentation/tier/`), not a hardcoded client constant.
- There is currently **no Dart model** for wallet balance. If the backend returns Cyclos'
  shape, add `WalletBalance { number, balance, availableBalance, reservedAmount, limit }`.

### 3. Users / tiers — signup & onboarding

- Cyclos groups: `tier1_member`, `tier_2_members` (naming is inconsistent in the ledger —
  treat the backend's tier number, not the Cyclos group string, as source of truth).
- Cyclos `create-new-user` returns `principals[].value` (the login username/number) and a
  numeric `user.id`. The backend should map Cyclos `user.id` ⟷ app `userId`
  (`UserModel.userId`) so later balance/transaction lookups resolve.

---

## Open questions for the backend team

1. Which `/api/v1/...` route returns the wallet **number + balance**? (drives Home screen)
2. Are transaction `amount`/`status`/`type` already normalized to app shape, or raw Cyclos?
3. Is `upperCreditLimit` the authoritative tier limit the app should display?
4. Confirm add-money credit path: `payments` (`fund_wallet`) vs `system/payments`.

## Security note

The Postman collection shared for this integration contains **plaintext production admin
passwords**. It is git-ignored (see `.gitignore`) and must not be committed, pasted into
issues, or stored in the repo. Ask the backend team to rotate those credentials if the
file has been circulated over chat/email.
