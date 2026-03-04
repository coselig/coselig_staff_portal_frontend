class SwitchGang {
  bool isScene;
  List<String> controlledLoopNames;

  SwitchGang({
    this.isScene = false,
    this.controlledLoopNames = const [],
  });

  SwitchGang copyWith({
    bool? isScene,
    List<String>? controlledLoopNames,
  }) {
    return SwitchGang(
      isScene: isScene ?? this.isScene,
      controlledLoopNames: controlledLoopNames ?? this.controlledLoopNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isScene': isScene,
      'controlledLoopNames': controlledLoopNames,
    };
  }

  factory SwitchGang.fromJson(Map<String, dynamic> json) {
    return SwitchGang(
      isScene: json['isScene'] == true,
      controlledLoopNames:
          (json['controlledLoopNames'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
