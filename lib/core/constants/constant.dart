/// 全局枚举和常量定义文件

/// 出入库标识 1 是出，0 是入
enum InOutStatus {
  outlet(1, '出库'),
  inlet(0, '入库');

  const InOutStatus(this.code, this.displayName);
  final int code;
  final String displayName;

  static InOutStatus fromCode(int code) {
    return InOutStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => InOutStatus.outlet,
    );
  }
}

// 任务状态枚举
/// 状态码：1-未执行，2-执行中，3-执行完成，4-已取消，5-作业异常
enum JobStatus {
  pending(1, 'PENDING'),
  running(2, 'RUNNING'),
  completed(3, 'COMPLETED'),
  cancelled(4, 'CANCELLED'),
  failed(5, 'FAILED');

  const JobStatus(this.code, this.value);
  final int code;
  final String value;

  @override
  String toString() => value;

  /// 根据状态码获取枚举值
  static JobStatus fromCode(int code) {
    return JobStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => JobStatus.pending,
    );
  }

  /// 根据字符串值获取枚举值
  static JobStatus fromValue(String value) {
    return JobStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => JobStatus.pending,
    );
  }

  /// 获取状态的中文描述
  String get displayName {
    switch (this) {
      case JobStatus.pending:
        return '未执行';
      case JobStatus.running:
        return '执行中';
      case JobStatus.completed:
        return '执行完成';
      case JobStatus.cancelled:
        return '已取消';
      case JobStatus.failed:
        return '作业异常';
    }
  }

  /// 获取状态的颜色代码
  String get colorCode {
    switch (this) {
      case JobStatus.pending:
        return '#FFA07A'; // 橙色
      case JobStatus.running:
        return '#87CEFA'; // 蓝色
      case JobStatus.completed:
        return '#90EE90'; // 绿色
      case JobStatus.cancelled:
        return '#D3D3D3'; // 灰色
      case JobStatus.failed:
        return '#CD5C5C'; // 红色
    }
  }
}

// 作业类型枚举
enum OperateType {
  location2location('location2location'),
  location2container('location2container');

  const OperateType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case OperateType.location2location:
        return '库位到库位搬运';
      case OperateType.location2container:
        return '库位到容器搬运';
    }
  }

  @override
  String toString() => value;
}

// 容器类型枚举
enum ContainerType {
  pallet('PALLET'),
  bin('BIN'),
  shelf('SHELF');

  const ContainerType(this.value);
  final String value;

  @override
  String toString() => value;
}

// 接口返回码枚举
enum HTTPCode {
  success('000000'),
  error('999999');

  const HTTPCode(this.code);
  final String code;
}

/// 地标类型
enum LocationType {
  unkown(0, '未知'),
  barrierType(1, '障碍物'),
  batteryType(2, '充电区'),
  queueType(3, '排队区'),
  spinType(4, '旋转区'),
  highwayType(5, '高速区'),
  turnningType(6, '转弯区'),
  restType(7, '暂驻区'),
  binType(8, '仓库储位'),
  workType(9, '工作区'),
  blockArea(10, '自动门'),
  windDoor(11, '风淋门'),
  bufferBinType(12, '产线缓冲区'),
  bufferCrossType(13, '缓冲交接区'),
  liftCrossType(14, '电梯交接区'),
  headCrossType(15, '线头交接区'),
  endCrossType(16, '产线交接区'),
  recoverCrossType(17, '回收交接区'),
  mapCrossType(18, '地图交接区'),
  corridorType(19, '入库交接区'),
  selfCheck(20, '自检区'),
  standBy(21, '待命点'),
  exchangeStationType(22, '换电站'),
  qrcrossType(23, '切至二维码'),
  slamcrossType(24, '切至slam'),
  wirelessBatteryType(25, '无线充电桩'),
  forkliftWaitType(26, '叉车等待点'),
  ctuWorkstationType(27, 'CTU工作站'),
  ctuWaitType(28, 'CTU等待点'),
  liftWaitType(29, '电梯等待点'),
  channelheadType(30, '巷道头'),
  channeltailType(31, '巷道尾'),
  channelbufferType(32, '巷道缓冲区'),
  batteryAssociatedType(33, '充电桩关联点'),
  arcArea(34, '弧线区');

  const LocationType(this.code, this.displayName);
  final int code;
  final String displayName;

  static LocationType fromCode(int code) {
    return LocationType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => LocationType.workType,
    );
  }
}

/// 地标状态 0-禁用 1-空闲 2-锁定 3-占用
enum LandmarkStatus {
  disabled(0, '禁用', '#708090'),
  idle(1, '空闲', '#32CD32'),
  locked(2, '锁定', '#DC143C'),
  occupied(3, '占用', '#FFA500');

  const LandmarkStatus(this.code, this.displayName, this.color);
  final int code;
  final String displayName;
  final String color;

  static LandmarkStatus fromCode(int code) {
    return LandmarkStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => LandmarkStatus.disabled,
    );
  }
}

/// 托盘类型 0-NULL(空) 1-FIXED_SHELF（固定货架) 2-MOVE_SHELF(移动货架) 3-虚拟库位(潜伏式AGV) 4-CHARGER(充电桩)
enum LandmarkType {
  none(0, '空'),
  fixedShelf(1, '固定货架'),
  moveShelf(2, '移动货架'),
  virtualLocation(3, '虚拟库位'),
  charger(4, '充电桩');

  const LandmarkType(this.code, this.displayName);
  final int code;
  final String displayName;

  static LandmarkType fromCode(int code) {
    return LandmarkType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => LandmarkType.none,
    );
  }
}

/// 托盘状态 0-禁用 1-空闲 2-锁定 3-占用 4-满载
enum PalletStatus {
  disabled(0, '禁用', '#708090'),
  idle(1, '空闲', '#32CD32'),
  locked(2, '锁定', '#DC143C'),
  occupied(3, '占用', '#FFA500'),
  full(4, '满载', '#8B0000');

  const PalletStatus(this.code, this.displayName, this.color);
  final int code;
  final String displayName;
  final String color;

  static PalletStatus fromCode(int code) {
    return PalletStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => PalletStatus.disabled,
    );
  }
}

/// 所属仓库
enum StorageCenter {
  haikang('001', '海康模拟仓');

  const StorageCenter(this.clrCenterNo, this.clrCenterName);
  final String clrCenterNo;
  final String clrCenterName;

  static StorageCenter fromCode(String clrCenterNo) {
    return StorageCenter.values.firstWhere(
      (data) => data.clrCenterNo == clrCenterNo,
      orElse: () => StorageCenter.haikang,
    );
  }
}

/// 库区类型
enum AreaType {
  storage('1', '存储库'),
  temporary('2', '暂存库'),
  inbound('3', '入库区'),
  handover('4', '交接库');

  const AreaType(this.code, this.displayName);
  final String code;
  final String displayName;

  static AreaType fromCode(String code) {
    return AreaType.values.firstWhere(
      (status) => status.code == code,
      orElse: () => AreaType.storage,
    );
  }
}

/// 库区状态 0-禁用 1-启用
enum AreaStatus {
  disabled(0, '禁用'),
  active(1, '启用');

  const AreaStatus(this.code, this.displayName);
  final int code;
  final String displayName;

  static AreaStatus fromCode(int code) {
    return AreaStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => AreaStatus.disabled,
    );
  }
}