/// Maps Chinese exercise names to local asset image paths.
/// Images sourced from free-exercise-db (public domain).
class ExerciseGifService {
  static String? assetPath(String chineseName) {
    if (_assets.contains(chineseName)) {
      return 'assets/exercises/$chineseName.jpg';
    }
    return null;
  }

  static const Set<String> _assets = {
    // 胸
    '平板卧推', '上斜卧推', '下斜卧推', '哑铃飞鸟', '俯卧撑',
    '双杠撑体', '钢线夹胸', '蝴蝶机夹胸',
    // 背
    '引体向上', '坐姿划船', '杠铃划船', '单臂哑铃划船',
    '高位下拉', '硬拉', '直腿硬拉', '俯身飞鸟',
    // 腿
    '深蹲', '腿举', '腿屈伸', '腿弯举', '弓步蹲',
    '保加利亚深蹲', '小腿提踵', '哈克深蹲',
    // 臀
    '臀桥', '单腿臀桥', '杠铃臀推', '负重臀推', '保加利亚深蹲（臀部主导）', '罗马尼亚硬拉（臀部主导）',
    '坐姿髋外展', '驴踢腿', '绳索后踢腿', '跪姿消防栓', '侧卧抬腿', '弹力带侧走', '蚌式开合',
    // 肩
    '哑铃肩推', '杠铃肩推', '侧平举', '前平举',
    '俯身侧平举', '绳索侧平举', '阿诺德推举',
    // 手臂
    '二头弯举', '锤式弯举', '集中弯举', '绳索弯举',
    '三头下压', '臂屈伸', '头后臂屈伸', '反握弯举',
    // 核心
    '卷腹', '平板支撑', '俄罗斯转体', '自行车卷腹',
    '侧平板支撑', '仰卧起坐', '悬挂举腿',
  };
}
