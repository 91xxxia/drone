/*
  简单测试数据生成脚本
  适用库：drone
  说明：生成基本的测试数据，避免复杂SQL语法
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 清理旧测试数据
DELETE FROM biz_patrol_result_media WHERE result_id IN (SELECT result_id FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES-%');
DELETE FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES-%';
DELETE FROM biz_patrol_task_log WHERE task_id IN (SELECT task_id FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK-%');
DELETE FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK-%';
DELETE FROM biz_patrol_route_point WHERE route_id IN (SELECT route_id FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%');
DELETE FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%';
DELETE FROM biz_usv_device WHERE device_code LIKE 'TEST-USV-%';

-- 插入设备数据
INSERT INTO biz_usv_device (device_code, device_name, device_model, endurance_minutes, camera_spec, owner_name, status, remark, create_by, create_time) VALUES
('TEST-USV-001', '测试无人船-01', 'USV-X1', 180, '4K/30fps 云台', '张三', 'normal', '测试设备-01', 'admin', NOW()),
('TEST-USV-002', '测试无人船-02', 'USV-X2', 150, '1080P 夜视', '李四', 'in_task', '测试设备-02', 'admin', NOW()),
('TEST-USV-003', '测试无人船-03', 'USV-Pro', 210, '4K/60fps 双目', '王五', 'normal', '测试设备-03', 'admin', NOW()),
('TEST-USV-004', '测试无人船-04', 'USV-Maint', 120, '1080P', '赵六', 'maintenance', '测试设备-04', 'admin', NOW()),
('TEST-USV-005', '测试无人船-05', 'USV-Edge', 160, '1080P 广角', '钱七', 'offline', '测试设备-05', 'admin', NOW());

-- 插入航线数据
INSERT INTO biz_patrol_route (route_name, est_duration_minutes, altitude, remark, create_by, create_time) VALUES
('TEST-航线A-沿江巡防', 45, 25.00, '测试航线A', 'admin', NOW()),
('TEST-航线B-港区巡防', 35, 20.00, '测试航线B', 'admin', NOW()),
('TEST-航线C-闸口巡防', 55, 30.00, '测试航线C', 'admin', NOW());

-- 获取航线ID变量
SET @routeA = NULL;
SET @routeB = NULL;
SET @routeC = NULL;

SELECT route_id INTO @routeA FROM biz_patrol_route WHERE route_name = 'TEST-航线A-沿江巡防' LIMIT 1;
SELECT route_id INTO @routeB FROM biz_patrol_route WHERE route_name = 'TEST-航线B-港区巡防' LIMIT 1;
SELECT route_id INTO @routeC FROM biz_patrol_route WHERE route_name = 'TEST-航线C-闸口巡防' LIMIT 1;

-- 插入航点数据
INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeA, 1, 112.9382100, 28.2284900),
(@routeA, 2, 112.9421100, 28.2312000),
(@routeA, 3, 112.9478000, 28.2339100),
(@routeB, 1, 112.9203000, 28.2181000),
(@routeB, 2, 112.9257000, 28.2204000),
(@routeB, 3, 112.9319000, 28.2226000),
(@routeC, 1, 112.9602000, 28.2401000),
(@routeC, 2, 112.9654000, 28.2427000),
(@routeC, 3, 112.9710000, 28.2461000);

-- 获取设备ID变量
SET @dev1 = NULL;
SET @dev2 = NULL;
SET @dev3 = NULL;
SET @dev4 = NULL;
SET @dev5 = NULL;

SELECT device_id INTO @dev1 FROM biz_usv_device WHERE device_code = 'TEST-USV-001' LIMIT 1;
SELECT device_id INTO @dev2 FROM biz_usv_device WHERE device_code = 'TEST-USV-002' LIMIT 1;
SELECT device_id INTO @dev3 FROM biz_usv_device WHERE device_code = 'TEST-USV-003' LIMIT 1;
SELECT device_id INTO @dev4 FROM biz_usv_device WHERE device_code = 'TEST-USV-004' LIMIT 1;
SELECT device_id INTO @dev5 FROM biz_usv_device WHERE device_code = 'TEST-USV-005' LIMIT 1;

-- 插入任务数据
INSERT INTO biz_patrol_task (task_code, task_name, executor, planned_start_time, task_desc, device_id, route_id, status, progress, start_time, end_time, create_by, create_time) VALUES
('TEST-TASK-001', '测试任务-001-日常巡防', '张三', DATE_ADD(NOW(), INTERVAL 1 DAY), '测试任务描述-001', @dev1, @routeA, 'pending', 0, NULL, NULL, 'admin', NOW()),
('TEST-TASK-002', '测试任务-002-专项检测', '李四', DATE_SUB(NOW(), INTERVAL 2 HOUR), '测试任务描述-002', @dev2, @routeB, 'running', 50, DATE_SUB(NOW(), INTERVAL 90 MINUTE), NULL, 'admin', NOW()),
('TEST-TASK-003', '测试任务-003-紧急巡查', '王五', DATE_SUB(NOW(), INTERVAL 1 DAY), '测试任务描述-003', @dev3, @routeC, 'completed', 100, DATE_SUB(NOW(), INTERVAL 26 HOUR), DATE_SUB(NOW(), INTERVAL 25 HOUR), 'admin', NOW()),
('TEST-TASK-004', '测试任务-004-定期维护', '赵六', DATE_SUB(NOW(), INTERVAL 6 HOUR), '测试任务描述-004', @dev4, @routeA, 'canceled', 0, NULL, DATE_SUB(NOW(), INTERVAL 5 HOUR), 'admin', NOW()),
('TEST-TASK-005', '测试任务-005-数据收集', '钱七', DATE_SUB(NOW(), INTERVAL 2 DAY), '测试任务描述-005', @dev5, @routeB, 'completed', 100, DATE_SUB(NOW(), INTERVAL 50 HOUR), DATE_SUB(NOW(), INTERVAL 49 HOUR), 'admin', NOW());

-- 获取任务ID变量
SET @task1 = NULL;
SET @task2 = NULL;
SET @task3 = NULL;
SET @task4 = NULL;
SET @task5 = NULL;

SELECT task_id INTO @task1 FROM biz_patrol_task WHERE task_code = 'TEST-TASK-001' LIMIT 1;
SELECT task_id INTO @task2 FROM biz_patrol_task WHERE task_code = 'TEST-TASK-002' LIMIT 1;
SELECT task_id INTO @task3 FROM biz_patrol_task WHERE task_code = 'TEST-TASK-003' LIMIT 1;
SELECT task_id INTO @task4 FROM biz_patrol_task WHERE task_code = 'TEST-TASK-004' LIMIT 1;
SELECT task_id INTO @task5 FROM biz_patrol_task WHERE task_code = 'TEST-TASK-005' LIMIT 1;

-- 插入任务日志
INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark) VALUES
(@task1, NULL, 'pending', 'admin', DATE_SUB(NOW(), INTERVAL 30 MINUTE), '任务创建'),
(@task2, NULL, 'pending', 'admin', DATE_SUB(NOW(), INTERVAL 2 HOUR), '任务创建'),
(@task2, 'pending', 'running', 'admin', DATE_SUB(NOW(), INTERVAL 90 MINUTE), '开始任务'),
(@task3, NULL, 'pending', 'admin', DATE_SUB(NOW(), INTERVAL 27 HOUR), '任务创建'),
(@task3, 'pending', 'running', 'admin', DATE_SUB(NOW(), INTERVAL 26 HOUR), '开始任务'),
(@task3, 'running', 'completed', 'admin', DATE_SUB(NOW(), INTERVAL 25 HOUR), '完成任务'),
(@task4, NULL, 'pending', 'admin', DATE_SUB(NOW(), INTERVAL 6 HOUR), '任务创建'),
(@task4, 'pending', 'canceled', 'admin', DATE_SUB(NOW(), INTERVAL 5 HOUR), '取消任务'),
(@task5, NULL, 'pending', 'admin', DATE_SUB(NOW(), INTERVAL 51 HOUR), '任务创建'),
(@task5, 'pending', 'running', 'admin', DATE_SUB(NOW(), INTERVAL 50 HOUR), '开始任务'),
(@task5, 'running', 'completed', 'admin', DATE_SUB(NOW(), INTERVAL 49 HOUR), '完成任务');

-- 插入结果数据
INSERT INTO biz_patrol_result (result_code, task_id, task_name, device_id, device_name, route_id, route_name, duration_minutes, completed_time, executor, overview, findings, handling, remark, create_by, create_time)
SELECT
    'TEST-RES-001',
    @task3,
    '测试任务-003-紧急巡查',
    @dev3,
    '测试无人船-03',
    @routeC,
    'TEST-航线C-闸口巡防',
    60,
    DATE_SUB(NOW(), INTERVAL 25 HOUR),
    '王五',
    '本次巡防任务正常完成，航线覆盖完整，未出现突发风险。',
    '发现一处疑似漂浮物，已记录坐标并复核。',
    '已通知值班人员人工复核，确认无安全隐患。',
    '测试数据：可在结果管理页查看并导出。',
    'admin',
    NOW()
UNION ALL
SELECT
    'TEST-RES-002',
    @task5,
    '测试任务-005-数据收集',
    @dev5,
    '测试无人船-05',
    @routeB,
    'TEST-航线B-港区巡防',
    45,
    DATE_SUB(NOW(), INTERVAL 49 HOUR),
    '钱七',
    '本次巡防任务正常完成，数据采集完整。',
    '未发现异常情况。',
    '无需特殊处理。',
    '测试数据：数据采集任务完成。',
    'admin',
    NOW();

-- 获取结果ID
SET @res1 = NULL;
SET @res2 = NULL;

SELECT result_id INTO @res1 FROM biz_patrol_result WHERE result_code = 'TEST-RES-001' LIMIT 1;
SELECT result_id INTO @res2 FROM biz_patrol_result WHERE result_code = 'TEST-RES-002' LIMIT 1;

-- 插入结果媒体数据
INSERT INTO biz_patrol_result_media (result_id, file_url, ai_tag, bbox_json, create_by, create_time) VALUES
(@res1, '/profile/upload/test/result_001_a.jpg', '漂浮物', '{"x":120,"y":80,"w":160,"h":110}', 'admin', NOW()),
(@res1, '/profile/upload/test/result_001_b.jpg', '船只', '{"x":300,"y":140,"w":180,"h":130}', 'admin', NOW()),
(@res2, '/profile/upload/test/result_002_a.jpg', '正常', '{"x":200,"y":100,"w":150,"h":120}', 'admin', NOW());

-- 更新设备状态
UPDATE biz_usv_device SET status = 'in_task', update_by = 'admin', update_time = NOW() WHERE device_code = 'TEST-USV-002';
UPDATE biz_usv_device SET status = 'normal', update_by = 'admin', update_time = NOW() WHERE device_code = 'TEST-USV-003';
UPDATE biz_usv_device SET status = 'normal', update_by = 'admin', update_time = NOW() WHERE device_code = 'TEST-USV-005';

SET FOREIGN_KEY_CHECKS = 1;

-- 显示统计信息
SELECT '测试数据生成完成' as message;
SELECT '设备数量', COUNT(*) FROM biz_usv_device WHERE device_code LIKE 'TEST-USV-%';
SELECT '航线数量', COUNT(*) FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%';
SELECT '任务数量', COUNT(*) FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK%';
SELECT '结果数量', COUNT(*) FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES%';
SELECT '媒体数量', COUNT(*) FROM biz_patrol_result_media WHERE result_id IN (SELECT result_id FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES%');