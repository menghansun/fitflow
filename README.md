# FitFlow 🏊💪

游泳 + 健身一体化运动记录 App，支持本地存储 + 云端同步（Supabase）。

---

## 功能概览

| 模块 | 功能 |
|------|------|
| 游泳记录 | 手动计时记圈，支持华为/小米运动健康截图 OCR 导入 |
| 健身记录 | 肌肉群分类 → 动作选择 → 组数/次数/重量，组间休息倒计时 |
| 有氧记录 | 心率区间记录，支持跑步等有氧类型 |
| 日历视图 | 月历显示运动打点，点击查看当日记录 |
| 统计分析 | 周/月数据图表，类型占比饼图，连续打卡天数 |
| 云端同步 | 邮箱注册登录，数据跨设备同步 |
| 主题 | 深色/浅色/跟随系统，实时切换 |

---

## 快速开始

### 1. 配置 Supabase（必选）

**公共项目无需配置即可体验，但建议使用自己的项目以确保数据安全。**

1. 创建 [Supabase](https://supabase.com) 项目
2. 在 SQL Editor 中运行以下建表语句：

```sql
-- profiles 表（用户资料）
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  nickname text default '我',
  avatar_emoji text,
  theme_mode_index int default 0,
  created_at timestamptz default now()
);
alter table profiles enable row level security;
create policy "Users can insert own profile" on profiles for insert with check (auth.uid() = id);
create policy "Users can read own profile" on profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

-- workouts 表（运动记录）
create table workouts (
  id text primary key,
  user_id uuid references auth.users on delete cascade,
  session_date timestamptz not null,
  type text not null,
  duration_seconds int default 0,
  heart_rate_avg int,
  heart_rate_max int,
  calories int,
  pool_length_meters int,
  total_distance_meters int,
  notes text,
  duration_minutes int,
  laps int,
  avg_pace text,
  swolf_avg int,
  stroke_count int,
  cardio_type text,
  end_date timestamptz,
  counts_as_workout boolean default true,
  local_updated_at bigint
);
alter table workouts enable row level security;
create policy "Users can insert own workouts" on workouts for insert with check (auth.uid() = user_id);
create policy "Users can read own workouts" on workouts for select using (auth.uid() = user_id);
create policy "Users can update own workouts" on workouts for update using (auth.uid() = user_id);
create policy "Users can delete own workouts" on workouts for delete using (auth.uid() = user_id);
```

3. 复制项目 URL 和 anon public key 到 `lib/config/supabase_config.dart`：

```dart
const String supabaseUrl = 'https://your-project.supabase.co';
const String supabaseAnonKey = 'your-anon-key';
```

### 2. 运行 App

```bash
# 1. 获取依赖
flutter pub get

# 2. 运行（debug）
flutter run

# 3. 构建 release APK
flutter build apk --release
# APK 路径: build/app/outputs/flutter-apk/app-release.apk
```

---

## 项目结构

```
lib/
├── main.dart                    # 入口，Provider 注册，路由
├── config/
│   └── supabase_config.dart     # Supabase 凭据（需填写，不提交 Git）
├── models/
│   ├── workout_session.dart     # 运动记录数据模型
│   └── app_user.dart            # 用户模型
├── providers/
│   ├── user_provider.dart       # 用户状态
│   └── workout_provider.dart    # 运动记录状态
├── services/
│   ├── hive_service.dart        # Hive 本地数据库初始化
│   └── supabase_service.dart    # Supabase 云端同步
├── screens/
│   ├── main_screen.dart         # 底部导航主框架
│   ├── home/home_screen.dart    # 首页
│   ├── swim/swim_record_screen.dart      # 游泳记录
│   ├── gym/gym_session_screen.dart      # 健身记录
│   ├── cardio/cardio_record_screen.dart  # 有氧记录
│   ├── other/other_activity_screen.dart  # 其他活动
│   ├── calendar/calendar_screen.dart     # 日历
│   ├── stats/stats_screen.dart           # 统计
│   └── profile/profile_screen.dart       # 我的
└── theme/
    └── app_theme.dart           # 深色/浅色主题定义
```

---

## 数据存储

- **本地**：Hive 数据库（离线可用），每用户独立 Box：`workouts_<userId>`
- **云端**：Supabase PostgreSQL，写入时同时写本地和云端，读取时优先本地 + 异步拉取云端（云端数据覆盖本地冲突）

---

## 主题色

| 用途 | 深色主题 | 浅色主题 |
|------|----------|----------|
| 背景 | `#0A0E1A` | `#F0F4F8` |
| 游泳强调色 | `#00D4FF` | `#00D4FF` |
| 健身强调色 | `#FF6B35` | `#FF6B35` |
| 有氧强调色 | `#34D399` | `#34D399` |

---

## 依赖

| 包 | 用途 |
|----|------|
| `hive` + `hive_flutter` | 本地数据库 |
| `provider` | 状态管理 |
| `supabase_flutter` | 云端同步 + 邮箱认证 |
| `table_calendar` | 日历组件 |
| `fl_chart` | 图表 |
| `uuid` | ID 生成 |
| `intl` | 日期格式化 |
| `shared_preferences` | 持久化当前用户 ID |

---

## 常见问题

**Q: Supabase 注册/登录失败？**
A: 检查 `lib/config/supabase_config.dart` 中的 URL 和 anon key 是否正确，以及 Supabase 项目是否开启了 Email Auth。

**Q: Hive 报 typeId 冲突？**
A: 各模型 typeId 已分配：WorkoutSession=6, AppUser=7。

**Q: 华为/小米运动健康截图 OCR 识别不准？**
A: 请尽量使用清晰、未过度压缩的竖屏详情页截图。解析入口见 `lib/services/ocr_service.dart`。

---

Made with ❤️ for fitness tracking
