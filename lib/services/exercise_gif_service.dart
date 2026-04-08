/// Maps Chinese exercise names to local asset image paths.
/// Images sourced from free-exercise-db (public domain).
class ExerciseGifService {
  static String? assetPath(String chineseName) {
    final file = _assetFiles[chineseName];
    if (file != null) {
      return 'assets/exercises/$file';
    }
    return null;
  }

  static const Map<String, String> _assetFiles = {
    // 胸
    '平板卧推': 'bench_press.gif',
    '上斜卧推': 'incline_bench_press.gif',
    '下斜卧推': 'incline_bench_press.gif',
    '哑铃飞鸟': 'pec_deck.gif',
    '俯卧撑': 'push_up.gif',
    '双杠撑体': 'push_up.gif',
    '钢线夹胸': 'cable_fly.gif',
    '绳索夹胸': 'cable_fly.gif',
    '蝴蝶机夹胸': 'pec_deck.gif',
    // 背
    '引体向上': 'lat_pulldown.gif',
    '辅助引体向上': 'assisted_pull_up.gif',
    '坐姿划船': 'seated_row.gif',
    '杠铃划船': 'barbell_row.gif',
    '杠铃俯身划船': 'barbell_row.gif',
    '单臂哑铃划船': 'one_arm_row.gif',
    '高位下拉': 'lat_pulldown.gif',
    '绳索直杆下拉': 'lat_pulldown.gif',
    '硬拉': 'romanian_deadlift.gif',
    '直腿硬拉': 'romanian_deadlift.gif',
    '俯身飞鸟': 'bent_over_lateral_raise.gif',
    '山羊挺身': 'back_extension.gif',
    // 臀腿
    '深蹲': 'squat.gif',
    '腿举': 'leg_press.gif',
    '腿屈伸': 'leg_curl.gif',
    '腿伸展': 'leg_extension.gif',
    '腿弯举': 'leg_curl.gif',
    '弓步蹲': 'bulgarian_split_squat.gif',
    '保加利亚深蹲': 'bulgarian_split_squat.gif',
    '小腿提踵': 'squat.gif',
    '哈克深蹲': 'leg_press.gif',
    '臀桥': 'glute_bridge.gif',
    '单腿臀桥': 'glute_bridge.gif',
    '杠铃臀推': 'barbell_hip_thrust.gif',
    '负重臀推': 'barbell_hip_thrust.gif',
    '保加利亚深蹲（臀部主导）': 'bulgarian_split_squat.gif',
    '罗马尼亚硬拉（臀部主导）': 'romanian_deadlift.gif',
    '坐姿髋外展': 'hip_abduction.gif',
    '驴踢腿': 'glute_bridge.gif',
    '绳索后踢腿': 'clamshell.gif',
    '跪姿消防栓': 'clamshell.gif',
    '侧卧抬腿': 'side_leg_raise.gif',
    '弹力带侧走': 'clamshell.gif',
    '蚌式开合': 'clamshell.gif',
    // 肩
    '哑铃肩推': 'shoulder_press.gif',
    '杠铃肩推': 'shoulder_press.gif',
    '侧平举': 'lateral_raise.gif',
    '前平举': 'lateral_raise.gif',
    '俯身侧平举': 'bent_over_lateral_raise.gif',
    '绳索侧平举': 'lateral_raise.gif',
    '阿诺德推举': 'arnold_press.gif',
    '面拉': 'face_pull.gif',
    '耸肩': 'shrug.gif',
    // 手臂
    '二头弯举': 'bicep_curl.gif',
    '锤式弯举': 'hammer_curl.gif',
    '集中弯举': 'bicep_curl.gif',
    '杠铃弯举': 'barbell_curl.gif',
    '绳索弯举': 'bicep_curl.gif',
    '三头下压': 'tricep_pushdown.gif',
    '绳索下压': 'tricep_pushdown.gif',
    '臂屈伸': 'push_up.gif',
    '平板臂屈伸': 'push_up.gif',
    '头后臂屈伸': 'tricep_pushdown.gif',
    '过头臂屈伸': 'tricep_pushdown.gif',
    '反握弯举': 'bicep_curl.gif',
    // 核心
    '卷腹': 'crunch.gif',
    '平板支撑': 'plank.gif',
    '俄罗斯转体': 'russian_twist.gif',
    '自行车卷腹': 'bicycle_crunch.gif',
    '侧平板支撑': 'plank.gif',
    '仰卧起坐': 'crunch.gif',
    '悬挂举腿': 'hanging_leg_raise.gif',
    '悬垂举腿': 'hanging_leg_raise.gif',
    '死虫式': 'dead_bug.gif',
    '鸟狗式': 'bird_dog.gif',
  };
}
