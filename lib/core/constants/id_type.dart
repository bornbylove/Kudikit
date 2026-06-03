enum IdType {
  bvn,
  nin,
}

extension IdTypeX on IdType {
  String get label {
    switch (this) {
      case IdType.bvn:
        return 'BVN';
      case IdType.nin:
        return 'NIN';
    }
  }

  String get hint {
    switch (this) {
      case IdType.bvn:
        return 'Enter your 11-digit BVN';
      case IdType.nin:
        return 'Enter your 11-digit NIN';
    }
  }
}
