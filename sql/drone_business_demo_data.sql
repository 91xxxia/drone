/*
 演示数据脚本（可重复执行）
 适用库：drone
 说明：
 1) 仅清理并重建 DEMO 前缀数据，不影响你的正式业务数据。
 2) 依赖表结构：sql/drone_business_init.sql
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- 0) 清理旧 DEMO 数据（按依赖顺序）
-- =====================================================

DELETE m
FROM biz_patrol_result_media m
JOIN biz_patrol_result r ON r.result_id = m.result_id
WHERE r.result_code LIKE 'DEMO-RES-%';

DELETE FROM biz_patrol_result WHERE result_code LIKE 'DEMO-RES-%';

DELETE l
FROM biz_patrol_task_log l
JOIN biz_patrol_task t ON t.task_id = l.task_id
WHERE t.task_code LIKE 'DEMO-TASK-%';

DELETE FROM biz_patrol_task WHERE task_code LIKE 'DEMO-TASK-%';

DELETE p
FROM biz_patrol_route_point p
JOIN biz_patrol_route r ON r.route_id = p.route_id
WHERE r.route_name LIKE 'DEMO-航线%';

DELETE FROM biz_patrol_route WHERE route_name LIKE 'DEMO-航线%';

DELETE FROM biz_usv_device WHERE device_code LIKE 'DEMO-USV-%';

-- =====================================================
-- 1) 设备数据
-- =====================================================

INSERT INTO biz_usv_device
(device_code, device_name, device_model, endurance_minutes, camera_spec, owner_name, status, remark, create_by, create_time)
VALUES
('DEMO-USV-001', '演示无人船-01', 'USV-X1', 180, '4K/30fps 云台', '张三', 'in_task', '用于执行中任务演示', 'admin', NOW()),
('DEMO-USV-002', '演示无人船-02', 'USV-X2', 150, '1080P 夜视', '李四', 'normal', '用于待执行任务演示', 'admin', NOW()),
('DEMO-USV-003', '演示无人船-03', 'USV-Pro', 210, '4K/60fps 双目', '王五', 'normal', '用于已完成任务演示', 'admin', NOW()),
('DEMO-USV-004', '演示无人船-04', 'USV-Maint', 120, '1080P', '赵六', 'maintenance', '维修中设备', 'admin', NOW()),
('DEMO-USV-005', '演示无人船-05', 'USV-Edge', 160, '1080P 广角', '钱七', 'offline', '离线设备', 'admin', NOW());

-- =====================================================
-- 2) 航线与点位
-- =====================================================

INSERT INTO biz_patrol_route
(route_name, est_duration_minutes, altitude, remark, create_by, create_time)
VALUES
('DEMO-航线A-沿江巡防', 45, 25.00, '沿江主干道巡防线', 'admin', NOW()),
('DEMO-航线B-港区巡防', 35, 20.00, '港区近岸巡防线', 'admin', NOW()),
('DEMO-航线C-闸口巡防', 55, 30.00, '闸口+支流巡防线', 'admin', NOW()),
('DEMO-航线D-备用巡防', 25, 18.00, '备用短航线', 'admin', NOW());

SET @routeA = (SELECT route_id FROM biz_patrol_route WHERE route_name = 'DEMO-航线A-沿江巡防' LIMIT 1);
SET @routeB = (SELECT route_id FROM biz_patrol_route WHERE route_name = 'DEMO-航线B-港区巡防' LIMIT 1);
SET @routeC = (SELECT route_id FROM biz_patrol_route WHERE route_name = 'DEMO-航线C-闸口巡防' LIMIT 1);
SET @routeD = (SELECT route_id FROM biz_patrol_route WHERE route_name = 'DEMO-航线D-备用巡防' LIMIT 1);

INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeA, 1, 112.9382100, 28.2284900),
(@routeA, 2, 112.9421100, 28.2312000),
(@routeA, 3, 112.9478000, 28.2339100),
(@routeA, 4, 112.9531000, 28.2357000);

INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeB, 1, 112.9203000, 28.2181000),
(@routeB, 2, 112.9257000, 28.2204000),
(@routeB, 3, 112.9319000, 28.2226000);

INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeC, 1, 112.9602000, 28.2401000),
(@routeC, 2, 112.9654000, 28.2427000),
(@routeC, 3, 112.9710000, 28.2461000),
(@routeC, 4, 112.9753000, 28.2490000),
(@routeC, 5, 112.9801000, 28.2516000);

INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES
(@routeD, 1, 112.9100000, 28.2100000),
(@routeD, 2, 112.9135000, 28.2123000),
(@routeD, 3, 112.9172000, 28.2141000);

-- =====================================================
-- 3) 任务与任务日志（覆盖4种状态）
-- =====================================================

SET @dev1 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'DEMO-USV-001' LIMIT 1);
SET @dev2 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'DEMO-USV-002' LIMIT 1);
SET @dev3 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'DEMO-USV-003' LIMIT 1);
SET @dev4 = (SELECT device_id FROM biz_usv_device WHERE device_code = 'DEMO-USV-004' LIMIT 1);

INSERT INTO biz_patrol_task
(task_code, task_name, executor, planned_start_time, task_desc, device_id, route_id, status, progress, start_time, end_time, create_by, create_time)
VALUES
('DEMO-TASK-001', '港区日常巡防（待执行）', '李四', DATE_ADD(NOW(), INTERVAL 1 DAY), '用于演示待执行任务', @dev2, @routeB, 'pending', 0, NULL, NULL, 'admin', NOW()),
('DEMO-TASK-002', '沿江巡防（执行中）', '张三', DATE_SUB(NOW(), INTERVAL 2 HOUR), '用于演示执行中任务和进度展示', @dev1, @routeA, 'running', 35, DATE_SUB(NOW(), INTERVAL 90 MINUTE), NULL, 'admin', NOW()),
('DEMO-TASK-003', '闸口专项巡防（已完成）', '王五', DATE_SUB(NOW(), INTERVAL 1 DAY), '用于演示完成后自动归档结果', @dev3, @routeC, 'completed', 100, DATE_SUB(NOW(), INTERVAL 26 HOUR), DATE_SUB(NOW(), INTERVAL 25 HOUR), 'admin', NOW()),
('DEMO-TASK-004', '备用航线测试（已取消）', '赵六', DATE_SUB(NOW(), INTERVAL 6 HOUR), '用于演示任务取消流程', @dev4, @routeD, 'canceled', 0, NULL, DATE_SUB(NOW(), INTERVAL 5 HOUR), 'admin', NOW());

SET @task1 = (SELECT task_id FROM biz_patrol_task WHERE task_code = 'DEMO-TASK-001' LIMIT 1);
SET @task2 = (SELECT task_id FROM biz_patrol_task WHERE task_code = 'DEMO-TASK-002' LIMIT 1);
SET @task3 = (SELECT task_id FROM biz_patrol_task WHERE task_code = 'DEMO-TASK-003' LIMIT 1);
SET @task4 = (SELECT task_id FROM biz_patrol_task WHERE task_code = 'DEMO-TASK-004' LIMIT 1);

INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark) VALUES
(@task1, NULL, 'pending', 'admin', DATE_SUB(NOW(), INTERVAL 30 MINUTE), '任务创建'),
(@task2, NULL, 'pending', 'admin', DATE_SUB(NOW(), INTERVAL 2 HOUR), '任务创建'),
(@task2, 'pending', 'running', 'admin', DATE_SUB(NOW(), INTERVAL 90 MINUTE), '开始任务'),
(@task3, NULL, 'pending', 'admin', DATE_SUB(NOW(), INTERVAL 27 HOUR), '任务创建'),
(@task3, 'pending', 'running', 'admin', DATE_SUB(NOW(), INTERVAL 26 HOUR), '开始任务'),
(@task3, 'running', 'completed', 'admin', DATE_SUB(NOW(), INTERVAL 25 HOUR), '完成任务'),
(@task4, NULL, 'pending', 'admin', DATE_SUB(NOW(), INTERVAL 6 HOUR), '任务创建'),
(@task4, 'pending', 'canceled', 'admin', DATE_SUB(NOW(), INTERVAL 5 HOUR), '取消任务');

-- =====================================================
-- 4) 结果与媒体（对应已完成任务）
-- =====================================================

INSERT INTO biz_patrol_result
(result_code, task_id, task_name, device_id, device_name, route_id, route_name,
 duration_minutes, completed_time, executor, overview, findings, handling, remark, create_by, create_time)
SELECT
  'DEMO-RES-001',
  t.task_id,
  t.task_name,
  t.device_id,
  d.device_name,
  t.route_id,
  r.route_name,
  60,
  t.end_time,
  t.executor,
  '本次巡防任务正常完成，航线覆盖完整，未出现突发风险。',
  '发现一处疑似漂浮物，已记录坐标并复核。',
  '已通知值班人员人工复核，确认无安全隐患。',
  '演示数据：可在结果管理页查看并导出。',
  'admin',
  NOW()
FROM biz_patrol_task t
JOIN biz_usv_device d ON d.device_id = t.device_id
JOIN biz_patrol_route r ON r.route_id = t.route_id
WHERE t.task_code = 'DEMO-TASK-003'
LIMIT 1;

SET @res1 = (SELECT result_id FROM biz_patrol_result WHERE result_code = 'DEMO-RES-001' LIMIT 1);

INSERT INTO biz_patrol_result_media (result_id, file_url, ai_tag, bbox_json, create_by, create_time)
VALUES
(@res1, '/profile/upload/demo/result_001_a.jpg', '漂浮物', '{"x":120,"y":80,"w":160,"h":110}', 'admin', NOW()),
(@res1, '/profile/upload/demo/result_001_b.jpg', '船只', '{"x":300,"y":140,"w":180,"h":130}', 'admin', NOW());

-- =====================================================
-- 5) 收尾（再次确保设备状态与任务状态一致）
-- =====================================================

UPDATE biz_usv_device SET status = 'in_task', update_by = 'admin', update_time = NOW() WHERE device_id = @dev1;
UPDATE biz_usv_device SET status = 'normal', update_by = 'admin', update_time = NOW() WHERE device_id = @dev2;
UPDATE biz_usv_device SET status = 'normal', update_by = 'admin', update_time = NOW() WHERE device_id = @dev3;
UPDATE biz_usv_device SET status = 'maintenance', update_by = 'admin', update_time = NOW() WHERE device_id = @dev4;

SET FOREIGN_KEY_CHECKS = 1;

-- 快速查看
SELECT 'biz_usv_device' AS table_name, COUNT(*) AS cnt FROM biz_usv_device WHERE device_code LIKE 'DEMO-USV-%'
UNION ALL
SELECT 'biz_patrol_route', COUNT(*) FROM biz_patrol_route WHERE route_name LIKE 'DEMO-航线%'
UNION ALL
SELECT 'biz_patrol_task', COUNT(*) FROM biz_patrol_task WHERE task_code LIKE 'DEMO-TASK-%'
UNION ALL
SELECT 'biz_patrol_result', COUNT(*) FROM biz_patrol_result WHERE result_code LIKE 'DEMO-RES-%';
