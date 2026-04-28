class Feature {
  final String title;
  final String description;

  Feature({required this.title, required this.description});

  // Create a Feature instance from a Map
  factory Feature.fromMap(Map<String, dynamic> map) {
    return Feature(title: map['title'], description: map['description']);
  }
}

class SubscriptionDetail {
  final String name;
  final List<String> description;
  final Map<String, Feature> features;

  SubscriptionDetail({
    required this.name,
    required this.description,
    required this.features,
  });

  // Create a SubscriptionDetail instance from a Map
  factory SubscriptionDetail.fromMap(String name, Map<String, dynamic> map) {
    var features = <String, Feature>{};

    // Populate the features map from the provided data
    map['features'].forEach((key, value) {
      features[key] = Feature(title: key, description: value);
    });

    return SubscriptionDetail(
      name: name,
      description: List<String>.from(map['description']),
      features: features,
    );
  }
}
