/*
  无人机/无人船测试数据生成脚本（修复版）
  适用库：drone
  说明：
  1) 生成大量测试数据用于性能测试和界面展示
  2) 可自定义生成数据量
  3) 与演示数据脚本不冲突，使用TEST前缀
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- 配置参数：可调整生成的数据量
-- =====================================================
SET @DEVICE_COUNT = 10;           -- 设备数量（已减少）
SET @ROUTE_COUNT = 5;             -- 航线数量（已减少）
SET @TASK_COUNT = 20;             -- 任务数量（已减少）

-- =====================================================
-- 0) 清理旧测试数据
-- =====================================================

DELETE m FROM biz_patrol_result_media m
JOIN biz_patrol_result r ON r.result_id = m.result_id
WHERE r.result_code LIKE 'TEST-RES-%';

DELETE FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES-%';

DELETE l FROM biz_patrol_task_log l
JOIN biz_patrol_task t ON t.task_id = l.task_id
WHERE t.task_code LIKE 'TEST-TASK-%';

DELETE FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK-%';

DELETE p FROM biz_patrol_route_point p
JOIN biz_patrol_route r ON r.route_id = p.route_id
WHERE r.route_name LIKE 'TEST-航线%';

DELETE FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%';

DELETE FROM biz_usv_device WHERE device_code LIKE 'TEST-USV-%';

-- =====================================================
-- 1) 生成设备测试数据
-- =====================================================

INSERT INTO biz_usv_device
(device_code, device_name, device_model, endurance_minutes, camera_spec, owner_name, status, remark, create_by, create_time)
VALUES
('TEST-USV-001', '测试无人船-01', 'USV-X1', 180, '4K/30fps 云台', '张三', 'normal', '测试设备-01，用于系统测试', 'admin', NOW()),
('TEST-USV-002', '测试无人船-02', 'USV-X2', 150, '1080P 夜视', '李四', 'in_task', '测试设备-02，用于系统测试', 'admin', NOW()),
('TEST-USV-003', '测试无人船-03', 'USV-Pro', 210, '4K/60fps 双目', '王五', 'normal', '测试设备-03，用于系统测试', 'admin', NOW()),
('TEST-USV-004', '测试无人船-04', 'USV-Maint', 120, '1080P', '赵六', 'maintenance', '测试设备-04，用于系统测试', 'admin', NOW()),
('TEST-USV-005', '测试无人船-05', 'USV-Edge', 160, '1080P 广角', '钱七', 'offline', '测试设备-05，用于系统测试', 'admin', NOW()),
('TEST-USV-006', '测试无人船-06', 'USV-X1', 190, '4K/30fps 云台', '孙八', 'normal', '测试设备-06，用于系统测试', 'admin', NOW()),
('TEST-USV-007', '测试无人船-07', 'USV-X2', 140, '1080P 夜视', '周九', 'normal', '测试设备-07，用于系统测试', 'admin', NOW()),
('TEST-USV-008', '测试无人船-08', 'USV-Pro', 200, '4K/60fps 双目', '吴十', 'in_task', '测试设备-08，用于系统测试', 'admin', NOW()),
('TEST-USV-009', '测试无人船-09', 'USV-Maint', 130, '1080P', '张三', 'normal', '测试设备-09，用于系统测试', 'admin', NOW()),
('TEST-USV-010', '测试无人船-10', 'USV-Edge', 170, '1080P 广角', '李四', 'maintenance', '测试设备-10，用于系统测试', 'admin', NOW());

-- =====================================================
-- 2) 生成航线测试数据
-- =====================================================

INSERT INTO biz_patrol_route
(route_name, est_duration_minutes, altitude, remark, create_by, create_time)
VALUES
('TEST-航线A-沿江巡防', 45, 25.00, '测试航线-1，用于系统测试', 'admin', NOW()),
('TEST-航线B-港区巡防', 35, 20.00, '测试航线-2，用于系统测试', 'admin', NOW()),
('TEST-航线C-闸口巡防', 55, 30.00, '测试航线-3，用于系统测试', 'admin', NOW()),
('TEST-航线D-备用巡防', 25, 18.00, '测试航线-4，用于系统测试', 'admin', NOW()),
('TEST-航线E-快速通道', 30, 22.00, '测试航线-5，用于系统测试', 'admin', NOW());

-- 获取航线ID并生成航点
SET @routeA = (SELECT route_id FROM biz_patrol_route WHERE route_name = 'TEST-航线A-沿江巡防' LIMIT 1);
SET @routeB = (SELECT route_id FROM biz_patrol_route WHERE route_name = 'TEST-航线B-港区巡防' LIMIT 1);
SET @routeC = (SELECT route_id FROM biz_patrol_route WHERE route_name = 'TEST-航线C-闸口巡防' LIMIT 1);
SET @routeD = (SELECT route_id FROM biz_patrol_route WHERE route_name = 'TEST-航线D-备用巡防' LIMIT 1);
SET @routeE = (SELECT route_id FROM biz_patrol_route WHERE route_name = 'TEST-航线E-快速通道' LIMIT 1);

-- 为航线A生成航点
INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeA, 1, 112.9382100, 28.2284900),
(@routeA, 2, 112.9421100, 28.2312000),
(@routeA, 3, 112.9478000, 28.2339100),
(@routeA, 4, 112.9531000, 28.2357000);

-- 为航线B生成航点
INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeB, 1, 112.9203000, 28.2181000),
(@routeB, 2, 112.9257000, 28.2204000),
(@routeB, 3, 112.9319000, 28.2226000);

-- 为航线C生成航点
INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeC, 1, 112.9602000, 28.2401000),
(@routeC, 2, 112.9654000, 28.2427000),
(@routeC, 3, 112.9710000, 28.2461000),
(@routeC, 4, 112.9753000, 28.2490000),
(@routeC, 5, 112.9801000, 28.2516000);

-- 为航线D生成航点
INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeD, 1, 112.9100000, 28.2100000),
(@routeD, 2, 112.9135000, 28.2123000),
(@routeD, 3, 112.9172000, 28.2141000);

-- 为航线E生成航点
INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeE, 1, 112.9850000, 28.2550000),
(@routeE, 2, 112.9885000, 28.2573000),
(@routeE, 3, 112.9922000, 28.2591000);

-- =====================================================
-- 3) 生成任务测试数据
-- =====================================================

-- 获取设备ID
SET @dev1 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-001' LIMIT 1);
SET @dev2 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-002' LIMIT 1);
SET @dev3 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-003' LIMIT 1);
SET @dev4 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-004' LIMIT 1);
SET @dev5 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-005' LIMIT 1);
SET @dev6 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-006' LIMIT 1);
SET @dev7 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-007' LIMIT 1);
SET @dev8 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-008' LIMIT 1);
SET @dev9 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-009' LIMIT 1);
SET @dev10 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'TEST-USV-010' LIMIT 1);

-- 插入任务数据
INSERT INTO biz_patrol_task
(task_code, task_name, executor, planned_start_time, task_desc, device_id, route_id, status, progress, start_time, end_time, create_by, create_time)
VALUES
-- 待执行任务
('TEST-TASK-0001', '测试任务-001-日常巡防', '张三', DATE_ADD(NOW(), INTERVAL 1 DAY), '测试任务描述-001', @dev1, @routeA, 'pending', 0, NULL, NULL, 'admin', NOW()),
('TEST-TASK-0002', '测试任务-002-专项检测', '李四', DATE_ADD(NOW(), INTERVAL 2 DAY), '测试任务描述-002', @dev2, @routeB, 'pending', 0, NULL, NULL, 'admin', NOW()),
('TEST-TASK-0003', '测试任务-003-紧急巡查', '王五', DATE_ADD(NOW(), INTERVAL 3 DAY), '测试任务描述-003', @dev3, @routeC, 'pending', 0, NULL, NULL, 'admin', NOW()),
('TEST-TASK-0004', '测试任务-004-定期维护', '赵六', DATE_ADD(NOW(), INTERVAL 4 DAY), '测试任务描述-004', @dev4, @routeD, 'pending', 0, NULL, NULL, 'admin', NOW()),
('TEST-TASK-0005', '测试任务-005-数据收集', '钱七', DATE_ADD(NOW(), INTERVAL 5 DAY), '测试任务描述-005', @dev5, @routeE, 'pending', 0, NULL, NULL, 'admin', NOW()),

-- 执行中任务
('TEST-TASK-0006', '测试任务-006-日常巡防', '孙八', DATE_SUB(NOW(), INTERVAL 2 HOUR), '测试任务描述-006', @dev6, @routeA, 'running', 25, DATE_SUB(NOW(), INTERVAL 90 MINUTE), NULL, 'admin', NOW()),
('TEST-TASK-0007', '测试任务-007-专项检测', '周九', DATE_SUB(NOW(), INTERVAL 3 HOUR), '测试任务描述-007', @dev7, @routeB, 'running', 50, DATE_SUB(NOW(), INTERVAL 120 MINUTE), NULL, 'admin', NOW()),
('TEST-TASK-0008', '测试任务-008-紧急巡查', '吴十', DATE_SUB(NOW(), INTERVAL 1 HOUR), '测试任务描述-008', @dev8, @routeC, 'running', 75, DATE_SUB(NOW(), INTERVAL 60 MINUTE), NULL, 'admin', NOW()),
('TEST-TASK-0009', '测试任务-009-定期维护', '张三', DATE_SUB(NOW(), INTERVAL 4 HOUR), '测试任务描述-009', @dev9, @routeD, 'running', 90, DATE_SUB(NOW(), INTERVAL 150 MINUTE), NULL, 'admin', NOW()),
('TEST-TASK-0010', '测试任务-010-数据收集', '李四', DATE_SUB(NOW(), INTERVAL 5 HOUR), '测试任务描述-010', @dev10, @routeE, 'running', 15, DATE_SUB(NOW(), INTERVAL 180 MINUTE), NULL, 'admin', NOW()),

-- 已完成任务
('TEST-TASK-0011', '测试任务-011-日常巡防', '王五', DATE_SUB(NOW(), INTERVAL 1 DAY), '测试任务描述-011', @dev1, @routeA, 'completed', 100, DATE_SUB(NOW(), INTERVAL 26 HOUR), DATE_SUB(NOW(), INTERVAL 25 HOUR), 'admin', NOW()),
('TEST-TASK-0012', '测试任务-012-专项检测', '赵六', DATE_SUB(NOW(), INTERVAL 2 DAY), '测试任务描述-012', @dev2, @routeB, 'completed', 100, DATE_SUB(NOW(), INTERVAL 50 HOUR), DATE_SUB(NOW(), INTERVAL 49 HOUR), 'admin', NOW()),
('TEST-TASK-0013', '测试任务-013-紧急巡查', '钱七', DATE_SUB(NOW(), INTERVAL 3 DAY), '测试任务描述-013', @dev3, @routeC, 'completed', 100, DATE_SUB(NOW(), INTERVAL 74 HOUR), DATE_SUB(NOW(), INTERVAL 73 HOUR), 'admin', NOW()),
('TEST-TASK-0014', '测试任务-014-定期维护', '孙八', DATE_SUB(NOW(), INTERVAL 4 DAY), '测试任务描述-014', @dev4, @routeD, 'completed', 100, DATE_SUB(NOW(), INTERVAL 98 HOUR), DATE_SUB(NOW(), INTERVAL 97 HOUR), 'admin', NOW()),
('TEST-TASK-0015', '测试任务-015-数据收集', '周九', DATE_SUB(NOW(), INTERVAL 5 DAY), '测试任务描述-015', @dev5, @routeE, 'completed', 100, DATE_SUB(NOW(), INTERVAL 122 HOUR), DATE_SUB(NOW(), INTERVAL 121 HOUR), 'admin', NOW()),

-- 已取消任务
('TEST-TASK-0016', '测试任务-016-日常巡防', '吴十', DATE_SUB(NOW(), INTERVAL 6 HOUR), '测试任务描述-016', @dev6, @routeA, 'canceled', 0, NULL, DATE_SUB(NOW(), INTERVAL 5 HOUR), 'admin', NOW()),
('TEST-TASK-0017', '测试任务-017-专项检测', '张三', DATE_SUB(NOW(), INTERVAL 7 HOUR), '测试任务描述-017', @dev7, @routeB, 'canceled', 20, DATE_SUB(NOW(), INTERVAL 8 HOUR), DATE_SUB(NOW(), INTERVAL 7 HOUR), 'admin', NOW()),
('TEST-TASK-0018', '测试任务-018-紧急巡查', '李四', DATE_SUB(NOW(), INTERVAL 8 HOUR), '测试任务描述-018', @dev8, @routeC, 'canceled', 10, NULL, DATE_SUB(NOW(), INTERVAL 7 HOUR), 'admin', NOW()),
('TEST-TASK-0019', '测试任务-019-定期维护', '王五', DATE_SUB(NOW(), INTERVAL 9 HOUR), '测试任务描述-019', @dev9, @routeD, 'canceled', 30, DATE_SUB(NOW(), INTERVAL 10 HOUR), DATE_SUB(NOW(), INTERVAL 9 HOUR), 'admin', NOW()),
('TEST-TASK-0020', '测试任务-020-数据收集', '赵六', DATE_SUB(NOW(), INTERVAL 10 HOUR), '测试任务描述-020', @dev10, @routeE, 'canceled', 5, NULL, DATE_SUB(NOW(), INTERVAL 9 HOUR), 'admin', NOW());

-- =====================================================
-- 4) 生成任务日志
-- =====================================================

-- 为所有任务添加创建日志
INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark)
SELECT
    task_id,
    NULL,
    'pending',
    'admin',
    DATE_SUB(create_time, INTERVAL FLOOR(1 + RAND() * 60) MINUTE),
    '任务创建'
FROM biz_patrol_task
WHERE task_code LIKE 'TEST-TASK-%';

-- 为运行中和已完成的任务添加开始日志
INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark)
SELECT
    task_id,
    'pending',
    'running',
    'admin',
    start_time,
    '开始任务'
FROM biz_patrol_task
WHERE task_code LIKE 'TEST-TASK-%' AND status IN ('running', 'completed') AND start_time IS NOT NULL;

-- 为已完成的任务添加完成日志
INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark)
SELECT
    task_id,
    'running',
    'completed',
    'admin',
    end_time,
    '任务完成'
FROM biz_patrol_task
WHERE task_code LIKE 'TEST-TASK-%' AND status = 'completed' AND end_time IS NOT NULL;

-- 为已取消的任务添加取消日志
INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark)
SELECT
    task_id,
    CASE WHEN start_time IS NULL THEN 'pending' ELSE 'running' END,
    'canceled',
    'admin',
    end_time,
    '任务取消'
FROM biz_patrol_task
WHERE task_code LIKE 'TEST-TASK-%' AND status = 'canceled';

-- =====================================================
-- 5) 生成结果数据（对应已完成任务）
-- =====================================================

INSERT INTO biz_patrol_result
(result_code, task_id, task_name, device_id, device_name, route_id, route_name,
 duration_minutes, completed_time, executor, overview, findings, handling, remark, create_by, create_time)
SELECT
    CONCAT('TEST-RES-', LPAD(t.task_id, 4, '0')),
    t.task_id,
    t.task_name,
    t.device_id,
    d.device_name,
    t.route_id,
    r.route_name,
    TIMESTAMPDIFF(MINUTE, t.start_time, t.end_time),
    t.end_time,
    t.executor,
    CASE
        WHEN RAND() < 0.8 THEN '本次巡防任务正常完成，航线覆盖完整，未发现异常情况。'
        ELSE '本次巡防任务完成，发现部分区域需要关注，已记录详细情况。'
    END,
    CASE
        WHEN RAND() < 0.6 THEN '未发现异常情况。'
        WHEN RAND() < 0.8 THEN '发现一处疑似漂浮物，已记录坐标。'
        ELSE '发现多处异常情况，包括漂浮物和船只异常停靠。'
    END,
    CASE
        WHEN RAND() < 0.7 THEN '无需特殊处理，继续正常监控。'
        ELSE '已通知相关人员关注，建议后续加强该区域巡查频率。'
    END,
    CONCAT('测试数据：任务ID ', t.task_id, ' 的自动生成的结果数据'),
    'admin',
    NOW()
FROM biz_patrol_task t
JOIN biz_usv_device d ON d.device_id = t.device_id
JOIN biz_patrol_route r ON r.route_id = t.route_id
WHERE t.task_code LIKE 'TEST-TASK-%' AND t.status = 'completed';

-- =====================================================
-- 6) 生成结果媒体数据
-- =====================================================

-- 为部分结果添加媒体文件
INSERT INTO biz_patrol_result_media (result_id, file_url, ai_tag, bbox_json, create_by, create_time)
SELECT
    r.result_id,
    CONCAT('/profile/upload/test/result_', LPAD(r.result_id, 4, '0'), '_a.jpg'),
    ELT(FLOOR(1 + RAND() * 5), '漂浮物', '船只', '人员', '障碍物', '正常'),
    CONCAT('{"x":', FLOOR(RAND() * 200), ',"y":', FLOOR(RAND() * 200), ',"w":', FLOOR(100 + RAND() * 100), ',"h":', FLOOR(80 + RAND() * 80), '}'),
    'admin',
    NOW()
FROM biz_patrol_result r
WHERE r.result_code LIKE 'TEST-RES-%' AND RAND() < 0.8;

-- 为部分结果添加第二个媒体文件
INSERT INTO biz_patrol_result_media (result_id, file_url, ai_tag, bbox_json, create_by, create_time)
SELECT
    r.result_id,
    CONCAT('/profile/upload/test/result_', LPAD(r.result_id, 4, '0'), '_b.jpg'),
    ELT(FLOOR(1 + RAND() * 5), '船只', '人员', '漂浮物', '正常', '障碍物'),
    CONCAT('{"x":', FLOOR(RAND() * 200), ',"y":', FLOOR(RAND() * 200), ',"w":', FLOOR(100 + RAND() * 100), ',"h":', FLOOR(80 + RAND() * 80), '}'),
    'admin',
    NOW()
FROM biz_patrol_result r
WHERE r.result_code LIKE 'TEST-RES-%' AND RAND() < 0.5;

-- =====================================================
-- 7) 更新设备状态以匹配任务状态
-- =====================================================

-- 将执行中任务对应的设备状态更新为in_task
UPDATE biz_usv_device d
JOIN biz_patrol_task t ON t.device_id = d.device_id AND t.status = 'running'
SET d.status = 'in_task', d.update_by = 'admin', d.update_time = NOW()
WHERE d.device_code LIKE 'TEST-USV-%';

-- 将已完成任务对应的设备状态更新为normal
UPDATE biz_usv_device d
JOIN biz_patrol_task t ON t.device_id = d.device_id AND t.status = 'completed'
SET d.status = 'normal', d.update_by = 'admin', d.update_time = NOW()
WHERE d.device_code LIKE 'TEST-USV-%' AND d.status != 'in_task';

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- 8) 统计信息
-- =====================================================

SELECT '测试数据生成完成' as message;

SELECT 'biz_usv_device' AS table_name, COUNT(*) AS count FROM biz_usv_device WHERE device_code LIKE