/*
 Navicat/MySQL 初始化脚本
 项目：无人船虚拟仿真系统（RuoYi-Vue3 二次开发）
 说明：
 1) 包含业务表DDL、字典初始化、菜单与按钮权限初始化、角色授权。
 2) 采用“可重复执行”策略：关键数据先按范围/类型清理再插入。
 3) 执行前请确认数据库已切换到目标库（如 drone）。
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- 1. 业务表 DDL
-- =====================================================

CREATE TABLE IF NOT EXISTS `biz_usv_device` (
  `device_id` bigint NOT NULL AUTO_INCREMENT COMMENT '设备主键',
  `device_code` varchar(64) NOT NULL COMMENT '设备编号（唯一）',
  `device_name` varchar(100) NOT NULL COMMENT '设备名称',
  `device_model` varchar(100) DEFAULT NULL COMMENT '设备型号',
  `endurance_minutes` int DEFAULT NULL COMMENT '续航时长（分钟）',
  `camera_spec` varchar(255) DEFAULT NULL COMMENT '摄像头参数',
  `owner_name` varchar(64) DEFAULT NULL COMMENT '归属人',
  `status` varchar(32) NOT NULL DEFAULT 'normal' COMMENT '设备状态：normal/maintenance/offline/in_task/scrapped',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`device_id`),
  UNIQUE KEY `uk_device_code` (`device_code`),
  KEY `idx_device_name` (`device_name`),
  KEY `idx_device_status` (`status`),
  KEY `idx_device_owner` (`owner_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='无人船设备表';

CREATE TABLE IF NOT EXISTS `biz_patrol_route` (
  `route_id` bigint NOT NULL AUTO_INCREMENT COMMENT '航线主键',
  `route_name` varchar(100) NOT NULL COMMENT '航线名称（唯一）',
  `est_duration_minutes` int DEFAULT NULL COMMENT '预计巡防时长（分钟）',
  `altitude` decimal(10,2) DEFAULT NULL COMMENT '航行高度（米）',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`route_id`),
  UNIQUE KEY `uk_route_name` (`route_name`),
  KEY `idx_route_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='巡防航线主表';

CREATE TABLE IF NOT EXISTS `biz_patrol_route_point` (
  `point_id` bigint NOT NULL AUTO_INCREMENT COMMENT '点位主键',
  `route_id` bigint NOT NULL COMMENT '航线ID',
  `seq` int NOT NULL COMMENT '点位序号',
  `lng` decimal(11,7) NOT NULL COMMENT '经度',
  `lat` decimal(10,7) NOT NULL COMMENT '纬度',
  PRIMARY KEY (`point_id`),
  UNIQUE KEY `uk_route_seq` (`route_id`,`seq`),
  KEY `idx_route_id` (`route_id`),
  CONSTRAINT `fk_route_point_route` FOREIGN KEY (`route_id`) REFERENCES `biz_patrol_route` (`route_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='巡防航线点位表';

CREATE TABLE IF NOT EXISTS `biz_patrol_task` (
  `task_id` bigint NOT NULL AUTO_INCREMENT COMMENT '任务主键',
  `task_code` varchar(64) NOT NULL COMMENT '任务编号（唯一）',
  `task_name` varchar(100) NOT NULL COMMENT '任务名称',
  `executor` varchar(64) DEFAULT NULL COMMENT '执行人',
  `planned_start_time` datetime NOT NULL COMMENT '计划开始时间',
  `task_desc` varchar(1000) DEFAULT NULL COMMENT '任务描述',
  `device_id` bigint NOT NULL COMMENT '绑定设备ID',
  `route_id` bigint NOT NULL COMMENT '绑定航线ID',
  `status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT '任务状态：pending/running/completed/canceled',
  `progress` int NOT NULL DEFAULT 0 COMMENT '任务进度（0-100）',
  `start_time` datetime DEFAULT NULL COMMENT '实际开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '实际结束时间',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`task_id`),
  UNIQUE KEY `uk_task_code` (`task_code`),
  KEY `idx_task_name` (`task_name`),
  KEY `idx_task_status` (`status`),
  KEY `idx_task_executor` (`executor`),
  KEY `idx_task_planned_start_time` (`planned_start_time`),
  KEY `idx_task_device` (`device_id`),
  KEY `idx_task_route` (`route_id`),
  CONSTRAINT `fk_task_device` FOREIGN KEY (`device_id`) REFERENCES `biz_usv_device` (`device_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_task_route` FOREIGN KEY (`route_id`) REFERENCES `biz_patrol_route` (`route_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_task_progress` CHECK (`progress` >= 0 AND `progress` <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='巡防任务表';

CREATE TABLE IF NOT EXISTS `biz_patrol_task_log` (
  `log_id` bigint NOT NULL AUTO_INCREMENT COMMENT '任务日志主键',
  `task_id` bigint NOT NULL COMMENT '任务ID',
  `from_status` varchar(32) DEFAULT NULL COMMENT '原状态',
  `to_status` varchar(32) NOT NULL COMMENT '目标状态',
  `operate_by` varchar(64) DEFAULT '' COMMENT '操作人',
  `operate_time` datetime NOT NULL COMMENT '操作时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`log_id`),
  KEY `idx_task_log_task_id` (`task_id`),
  KEY `idx_task_log_operate_time` (`operate_time`),
  CONSTRAINT `fk_task_log_task` FOREIGN KEY (`task_id`) REFERENCES `biz_patrol_task` (`task_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='任务状态流转日志表';

CREATE TABLE IF NOT EXISTS `biz_patrol_result` (
  `result_id` bigint NOT NULL AUTO_INCREMENT COMMENT '结果主键',
  `result_code` varchar(64) NOT NULL COMMENT '结果编号（唯一）',
  `task_id` bigint NOT NULL COMMENT '关联任务ID（唯一）',
  `task_name` varchar(100) NOT NULL COMMENT '任务名称快照',
  `device_id` bigint NOT NULL COMMENT '设备ID',
  `device_name` varchar(100) NOT NULL COMMENT '设备名称快照',
  `route_id` bigint NOT NULL COMMENT '航线ID',
  `route_name` varchar(100) NOT NULL COMMENT '航线名称快照',
  `duration_minutes` int DEFAULT NULL COMMENT '巡防时长（分钟）',
  `completed_time` datetime NOT NULL COMMENT '完成时间',
  `executor` varchar(64) DEFAULT NULL COMMENT '执行人',
  `overview` varchar(2000) NOT NULL COMMENT '巡防概述（必填）',
  `findings` varchar(4000) DEFAULT NULL COMMENT '发现情况',
  `handling` varchar(4000) DEFAULT NULL COMMENT '处理情况',
  `remark` varchar(1000) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`result_id`),
  UNIQUE KEY `uk_result_code` (`result_code`),
  UNIQUE KEY `uk_result_task_id` (`task_id`),
  KEY `idx_result_completed_time` (`completed_time`),
  KEY `idx_result_executor` (`executor`),
  CONSTRAINT `fk_result_task` FOREIGN KEY (`task_id`) REFERENCES `biz_patrol_task` (`task_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_result_device` FOREIGN KEY (`device_id`) REFERENCES `biz_usv_device` (`device_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_result_route` FOREIGN KEY (`route_id`) REFERENCES `biz_patrol_route` (`route_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='巡防结果表';

CREATE TABLE IF NOT EXISTS `biz_patrol_result_media` (
  `media_id` bigint NOT NULL AUTO_INCREMENT COMMENT '媒体主键',
  `result_id` bigint NOT NULL COMMENT '结果ID',
  `file_url` varchar(500) NOT NULL COMMENT '图片/文件URL',
  `ai_tag` varchar(100) DEFAULT NULL COMMENT 'AI识别标签',
  `bbox_json` varchar(2000) DEFAULT NULL COMMENT 'AI框选坐标JSON',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`media_id`),
  KEY `idx_result_media_result_id` (`result_id`),
  CONSTRAINT `fk_result_media_result` FOREIGN KEY (`result_id`) REFERENCES `biz_patrol_result` (`result_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='巡防结果媒体表（AI扩展）';

-- =====================================================
-- 2. 字典初始化（设备状态/任务状态）
-- =====================================================

DELETE FROM `sys_dict_data` WHERE `dict_type` IN ('drone_device_status', 'drone_task_status');
DELETE FROM `sys_dict_type` WHERE `dict_type` IN ('drone_device_status', 'drone_task_status');

INSERT INTO `sys_dict_type` (`dict_name`,`dict_type`,`status`,`create_by`,`create_time`,`remark`) VALUES
('无人船设备状态','drone_device_status','0','admin',NOW(),'无人船设备状态字典'),
('无人船任务状态','drone_task_status','0','admin',NOW(),'无人船任务状态字典');

INSERT INTO `sys_dict_data` (`dict_sort`,`dict_label`,`dict_value`,`dict_type`,`css_class`,`list_class`,`is_default`,`status`,`create_by`,`create_time`,`remark`) VALUES
(1,'正常','normal','drone_device_status','','primary','Y','0','admin',NOW(),'可执行任务'),
(2,'维修中','maintenance','drone_device_status','','warning','N','0','admin',NOW(),'不可执行任务'),
(3,'离线','offline','drone_device_status','','info','N','0','admin',NOW(),'不可执行任务'),
(4,'任务中','in_task','drone_device_status','','success','N','0','admin',NOW(),'任务执行中'),
(5,'已报废','scrapped','drone_device_status','','danger','N','0','admin',NOW(),'不可执行任务'),
(1,'待执行','pending','drone_task_status','','info','Y','0','admin',NOW(),'任务新建默认状态'),
(2,'执行中','running','drone_task_status','','warning','N','0','admin',NOW(),'任务进行中'),
(3,'已完成','completed','drone_task_status','','success','N','0','admin',NOW(),'任务完成并生成结果'),
(4,'已取消','canceled','drone_task_status','','danger','N','0','admin',NOW(),'任务取消不生成结果');

-- =====================================================
-- 3. 菜单与按钮权限初始化
--    约定ID区间：3000-3199（无人船巡防模块）
-- =====================================================

DELETE FROM `sys_role_menu` WHERE `menu_id` BETWEEN 3000 AND 3199;
DELETE FROM `sys_menu` WHERE `menu_id` BETWEEN 3000 AND 3199;

-- 一级目录
INSERT INTO `sys_menu` (`menu_id`,`menu_name`,`parent_id`,`order_num`,`path`,`component`,`query`,`route_name`,`is_frame`,`is_cache`,`menu_type`,`visible`,`status`,`perms`,`icon`,`create_by`,`create_time`,`remark`) VALUES
(3000,'无人船巡防',0,5,'drone',NULL,'','','1','0','M','0','0','','guide','admin',NOW(),'无人船巡防目录');

-- 二级菜单
INSERT INTO `sys_menu` (`menu_id`,`menu_name`,`parent_id`,`order_num`,`path`,`component`,`query`,`route_name`,`is_frame`,`is_cache`,`menu_type`,`visible`,`status`,`perms`,`icon`,`create_by`,`create_time`,`remark`) VALUES
(3001,'数据概览',3000,1,'dashboard','drone/dashboard/index','','DroneDashboard',1,0,'C','0','0','drone:dashboard:view','dashboard','admin',NOW(),'无人船概览菜单'),
(3002,'设备管理',3000,2,'device','drone/device/index','','DroneDevice',1,0,'C','0','0','drone:device:list','tree','admin',NOW(),'设备管理菜单'),
(3003,'航线管理',3000,3,'route','drone/route/index','','DroneRoute',1,0,'C','0','0','drone:route:list','guide','admin',NOW(),'航线管理菜单'),
(3004,'任务管理',3000,4,'task','drone/task/index','','DroneTask',1,0,'C','0','0','drone:task:list','job','admin',NOW(),'任务管理菜单'),
(3005,'结果管理',3000,5,'result','drone/result/index','','DroneResult',1,0,'C','0','0','drone:result:list','form','admin',NOW(),'结果管理菜单');

-- 设备按钮
INSERT INTO `sys_menu` (`menu_id`,`menu_name`,`parent_id`,`order_num`,`path`,`component`,`query`,`route_name`,`is_frame`,`is_cache`,`menu_type`,`visible`,`status`,`perms`,`icon`,`create_by`,`create_time`,`remark`) VALUES
(3100,'设备查询',3002,1,'','','','',1,0,'F','0','0','drone:device:query','#','admin',NOW(),''),
(3101,'设备新增',3002,2,'','','','',1,0,'F','0','0','drone:device:add','#','admin',NOW(),''),
(3102,'设备修改',3002,3,'','','','',1,0,'F','0','0','drone:device:edit','#','admin',NOW(),''),
(3103,'设备删除',3002,4,'','','','',1,0,'F','0','0','drone:device:remove','#','admin',NOW(),''),
(3104,'设备导出',3002,5,'','','','',1,0,'F','0','0','drone:device:export','#','admin',NOW(),''),
(3105,'设备详情',3002,6,'','','','',1,0,'F','0','0','drone:device:detail','#','admin',NOW(),'');

-- 航线按钮
INSERT INTO `sys_menu` (`menu_id`,`menu_name`,`parent_id`,`order_num`,`path`,`component`,`query`,`route_name`,`is_frame`,`is_cache`,`menu_type`,`visible`,`status`,`perms`,`icon`,`create_by`,`create_time`,`remark`) VALUES
(3110,'航线查询',3003,1,'','','','',1,0,'F','0','0','drone:route:query','#','admin',NOW(),''),
(3111,'航线新增',3003,2,'','','','',1,0,'F','0','0','drone:route:add','#','admin',NOW(),''),
(3112,'航线修改',3003,3,'','','','',1,0,'F','0','0','drone:route:edit','#','admin',NOW(),''),
(3113,'航线删除',3003,4,'','','','',1,0,'F','0','0','drone:route:remove','#','admin',NOW(),''),
(3114,'航线详情',3003,5,'','','','',1,0,'F','0','0','drone:route:detail','#','admin',NOW(),''),
(3115,'航线绘制',3003,6,'','','','',1,0,'F','0','0','drone:route:draw','#','admin',NOW(),'');

-- 任务按钮
INSERT INTO `sys_menu` (`menu_id`,`menu_name`,`parent_id`,`order_num`,`path`,`component`,`query`,`route_name`,`is_frame`,`is_cache`,`menu_type`,`visible`,`status`,`perms`,`icon`,`create_by`,`create_time`,`remark`) VALUES
(3120,'任务查询',3004,1,'','','','',1,0,'F','0','0','drone:task:query','#','admin',NOW(),''),
(3121,'任务新增',3004,2,'','','','',1,0,'F','0','0','drone:task:add','#','admin',NOW(),''),
(3122,'任务开始',3004,3,'','','','',1,0,'F','0','0','drone:task:start','#','admin',NOW(),''),
(3123,'任务完成',3004,4,'','','','',1,0,'F','0','0','drone:task:finish','#','admin',NOW(),''),
(3124,'任务取消',3004,5,'','','','',1,0,'F','0','0','drone:task:cancel','#','admin',NOW(),''),
(3125,'任务删除',3004,6,'','','','',1,0,'F','0','0','drone:task:remove','#','admin',NOW(),''),
(3126,'任务详情',3004,7,'','','','',1,0,'F','0','0','drone:task:detail','#','admin',NOW(),'');

-- 结果按钮
INSERT INTO `sys_menu` (`menu_id`,`menu_name`,`parent_id`,`order_num`,`path`,`component`,`query`,`route_name`,`is_frame`,`is_cache`,`menu_type`,`visible`,`status`,`perms`,`icon`,`create_by`,`create_time`,`remark`) VALUES
(3130,'结果查询',3005,1,'','','','',1,0,'F','0','0','drone:result:query','#','admin',NOW(),''),
(3131,'结果修改',3005,2,'','','','',1,0,'F','0','0','drone:result:edit','#','admin',NOW(),''),
(3132,'结果删除',3005,3,'','','','',1,0,'F','0','0','drone:result:remove','#','admin',NOW(),''),
(3133,'结果导出',3005,4,'','','','',1,0,'F','0','0','drone:result:export','#','admin',NOW(),''),
(3134,'结果详情',3005,5,'','','','',1,0,'F','0','0','drone:result:detail','#','admin',NOW(),'');

-- =====================================================
-- 4. 角色授权（admin/common）
-- =====================================================

-- 管理员：授予模块全部菜单/按钮
INSERT IGNORE INTO `sys_role_menu` (`role_id`,`menu_id`)
SELECT 1, m.menu_id
FROM `sys_menu` m
WHERE m.menu_id BETWEEN 3000 AND 3199;

-- 普通角色：仅查看权限（目录、菜单、查询/详情）
INSERT IGNORE INTO `sys_role_menu` (`role_id`,`menu_id`) VALUES
(2,3000),(2,3001),(2,3002),(2,3003),(2,3004),(2,3005),
(2,3100),(2,3105),
(2,3110),(2,3114),
(2,3120),(2,3126),
(2,3130),(2,3134);

-- =====================================================
-- 5. 可选：普通角色“权限瘦身”模板（默认不执行）
--    如需严格只读，可先清理 role_id=2 的系统权限再按需回灌。
-- =====================================================
/*
-- DELETE FROM sys_role_menu WHERE role_id = 2;
-- 然后按你最终设计回灌 role_id=2 所需菜单与按钮
*/

SET FOREIGN_KEY_CHECKS = 1;
