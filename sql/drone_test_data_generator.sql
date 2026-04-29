/*
  无人机/无人船测试数据生成脚本
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
SET @DEVICE_COUNT = 20;           -- 设备数量
SET @ROUTE_COUNT = 15;            -- 航线数量
SET @TASK_COUNT = 10;            -- 任务数量
SET @RESULT_RATIO = 0.7;          -- 已完成任务比例

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

SET @device_sql = CONCAT('
INSERT INTO biz_usv_device
(device_code, device_name, device_model, endurance_minutes, camera_spec, owner_name, status, remark, create_by, create_time)
VALUES
';

SET @i = 1;
SET @values = '';

WHILE @i <= @DEVICE_COUNT DO
    SET @device_code = CONCAT('TEST-USV-', LPAD(@i, 3, '0'));
    SET @device_name = CONCAT('测试无人船-', @i);

    -- 随机设备型号
    SET @model = ELT(FLOOR(1 + RAND() * 5), 'USV-X1', 'USV-X2', 'USV-Pro', 'USV-Maint', 'USV-Edge');

    -- 随机续航时间 (120-240分钟)
    SET @endurance = FLOOR(120 + RAND() * 121);

    -- 随机摄像头规格
    SET @camera = ELT(FLOOR(1 + RAND() * 4), '1080P', '1080P 夜视', '4K/30fps 云台', '4K/60fps 双目');

    -- 随机状态
    SET @status = ELT(FLOOR(1 + RAND() * 4), 'normal', 'in_task', 'maintenance', 'offline');

    -- 随机归属人
    SET @owner = ELT(FLOOR(1 + RAND() * 8), '张三', '李四', '王五', '赵六', '钱七', '孙八', '周九', '吴十');

    SET @remark = CONCAT('测试设备-', @i, '，用于系统测试');

    IF @i > 1 THEN SET @values = CONCAT(@values, ','); END IF;

    SET @values = CONCAT(@values,
        '(\'', @device_code, '\', \'', @device_name, '\', \'', @model, '\', ',,
        @endurance, \', \'', @camera, \', \'', @owner, \', \'', @status, \', \'', @remark, \', \'admin\', NOW())');

    SET @i = @i + 1;
END WHILE;

SET @device_sql = CONCAT(@device_sql, @values);

-- 执行设备插入
PREPARE stmt FROM @device_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =====================================================
-- 2) 生成航线测试数据
-- =====================================================

SET @route_sql = CONCAT('
INSERT INTO biz_patrol_route
(route_name, est_duration_minutes, altitude, remark, create_by, create_time)
VALUES
');

SET @i = 1;
SET @values = '';

WHILE @i <= @ROUTE_COUNT DO
    SET @route_name = CONCAT('TEST-航线', CHAR(64 + @i), '-',
        ELT(FLOOR(1 + RAND() * 6), '沿江巡防', '港区巡防', '闸口巡防', '备用巡防', '快速通道', '深度检测'));

    -- 随机预计时长 (20-90分钟)
    SET @duration = FLOOR(20 + RAND() * 71);

    -- 随机高度 (15-35米)
    SET @altitude = ROUND(15 + RAND() * 20, 2);

    SET @remark = CONCAT('测试航线-', @i, '，用于系统测试');

    IF @i > 1 THEN SET @values = CONCAT(@values, ','); END IF;

    SET @values = CONCAT(@values,
        '(\'', @route_name, '\', ',', @duration, ',', @altitude, \', \'', @remark, \', \'admin\', NOW())');

    SET @i = @i + 1;
END WHILE;

SET @route_sql = CONCAT(@route_sql, @values);

-- 执行航线插入
PREPARE stmt FROM @route_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 获取航线ID并生成航点
SET @i = 1;
WHILE @i <= @ROUTE_COUNT DO
    SET @route_id = (SELECT route_id FROM biz_patrol_route WHERE route_name LIKE CONCAT('TEST-航线', CHAR(64 + @i), '-%') LIMIT 1);

    -- 为每条航线生成3-8个航点
    SET @point_count = FLOOR(3 + RAND() * 6);
    SET @j = 1;

    WHILE @j <= @point_count DO
        -- 生成随机坐标（基于基础坐标的偏移）
        SET @base_lng = 112.9000000 + RAND() * 0.1000000;
        SET @base_lat = 28.2000000 + RAND() * 0.1000000;

        INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat)
        VALUES (@route_id, @j, @base_lng, @base_lat);

        SET @j = @j + 1;
    END WHILE;

    SET @i = @i + 1;
END WHILE;

-- =====================================================
-- 3) 生成任务测试数据
-- =====================================================

SET @task_sql = CONCAT('
INSERT INTO biz_patrol_task
(task_code, task_name, executor, planned_start_time, task_desc, device_id, route_id, status, progress, start_time, end_time, create_by, create_time)
VALUES
');

SET @i = 1;
SET @values = '';

WHILE @i <= @TASK_COUNT DO
    SET @task_code = CONCAT('TEST-TASK-', LPAD(@i, 4, '0'));

    -- 随机任务名称
    SET @task_name = CONCAT('测试任务-', @i, '-',
        ELT(FLOOR(1 + RAND() * 5), '日常巡防', '专项检测', '紧急巡查', '定期维护', '数据收集'));

    -- 随机执行人
    SET @executor = ELT(FLOOR(1 + RAND() * 8), '张三', '李四', '王五', '赵六', '钱七', '孙八', '周九', '吴十');

    -- 随机计划开始时间（过去7天内或未来3天内）
    SET @planned_start = DATE_ADD(NOW(), INTERVAL FLOOR(-7*24 + RAND() * 10*24) HOUR);

    SET @task_desc = CONCAT('测试任务描述-', @i);

    -- 随机设备和航线
    SET @device_id = (SELECT device_id FROM biz_usv_device WHERE device_code LIKE 'TEST-USV-%' ORDER BY RAND() LIMIT 1);
    SET @route_id = (SELECT route_id FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%' ORDER BY RAND() LIMIT 1);

    -- 随机状态
    SET @status_num = RAND();
    IF @status_num < 0.3 THEN
        SET @status = 'pending';
        SET @progress = 0;
        SET @start_time = NULL;
        SET @end_time = NULL;
    ELSEIF @status_num < 0.6 THEN
        SET @status = 'running';
        SET @progress = FLOOR(20 + RAND() * 70);
        SET @start_time = DATE_SUB(NOW(), INTERVAL FLOOR(1 + RAND() * 48) HOUR);
        SET @end_time = NULL;
    ELSEIF @status_num < 0.9 THEN
        SET @status = 'completed';
        SET @progress = 100;
        SET @start_time = DATE_SUB(NOW(), INTERVAL FLOOR(2 + RAND() * 72) HOUR);
        SET @end_time = DATE_ADD(@start_time, INTERVAL FLOOR(30 + RAND() * 120) MINUTE);
    ELSE
        SET @status = 'canceled';
        SET @progress = FLOOR(RAND() * 50);
        SET @start_time = NULL;
        SET @end_time = DATE_SUB(NOW(), INTERVAL FLOOR(1 + RAND() * 24) HOUR);
    END IF;

    IF @i > 1 THEN SET @values = CONCAT(@values, ','); END IF;

    SET @values = CONCAT(@values,
        '(\'', @task_code, '\', \'', @task_name, '\', \'', @executor, '\', \'', @planned_start, \', \'',
        @task_desc, \', ', @device_id, ',', @route_id, \', \'', @status, \', ', @progress, \', ',
        IF(@start_time IS NULL, 'NULL', CONCAT('\'', @start_time, '\'')), \', ',
        IF(@end_time IS NULL, 'NULL', CONCAT('\'', @end_time, '\'')), \', \'admin\', NOW())');

    SET @i = @i + 1;
END WHILE;

SET @task_sql = CONCAT(@task_sql, @values);

-- 执行任务插入
PREPARE stmt FROM @task_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =====================================================
-- 4) 生成任务日志
-- =====================================================

INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark)
SELECT
    t.task_id,
    NULL,
    'pending',
    'admin',
    DATE_SUB(t.create_time, INTERVAL FLOOR(1 + RAND() * 60) MINUTE),
    '任务创建'
FROM biz_patrol_task t
WHERE t.task_code LIKE 'TEST-TASK-%';

-- 为运行中和已完成的任务添加开始日志
INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark)
SELECT
    t.task_id,
    'pending',
    'running',
    'admin',
    t.start_time,
    '开始任务'
FROM biz_patrol_task t
WHERE t.task_code LIKE 'TEST-TASK-%' AND t.status IN ('running', 'completed') AND t.start_time IS NOT NULL;

-- 为已完成的任务添加完成日志
INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark)
SELECT
    t.task_id,
    'running',
    'completed',
    'admin',
    t.end_time,
    '任务完成'
FROM biz_patrol_task t
WHERE t.task_code LIKE 'TEST-TASK-%' AND t.status = 'completed' AND t.end_time IS NOT NULL;

-- 为已取消的任务添加取消日志
INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark)
SELECT
    t.task_id,
    IF(t.start_time IS NULL, 'pending', 'running'),
    'canceled',
    'admin',
    t.end_time,
    '任务取消'
FROM biz_patrol_task t
WHERE t.task_code LIKE 'TEST-TASK-%' AND t.status = 'canceled';

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

INSERT INTO biz_patrol_result_media (result_id, file_url, ai_tag, bbox_json, create_by, create_time)
SELECT
    r.result_id,
    CONCAT('/profile/upload/test/result_', LPAD(r.result_id, 4, '0'), '_a.jpg'),
    ELT(FLOOR(1 + RAND() * 5), '漂浮物', '船只', '人员', '障碍物', '正常'),
    CONCAT('{"x":', FLOOR(RAND() * 200), ',"y":', FLOOR(RAND() * 200), ',"w":', FLOOR(100 + RAND() * 100), ',"h":', FLOOR(80 + RAND() * 80), '}'),
    'admin',
    NOW()
FROM biz_patrol_result r
WHERE r.result_code LIKE 'TEST-RES-%' AND RAND() < 0.6;

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
WHERE r.result_code LIKE 'TEST-RES-%' AND RAND() < 0.3;

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

SELECT 'biz_usv_device' AS table_name, COUNT(*) AS count FROM biz_usv_device WHERE device_code LIKE 'TEST-USV-%'
UNION ALL
SELECT 'biz_patrol_route', COUNT(*) FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%'
UNION ALL
SELECT 'biz_patrol_task', COUNT(*) FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK-%'
UNION ALL
SELECT 'biz_patrol_result', COUNT(*) FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES-%'
UNION ALL
SELECT 'biz_patrol_result_media', COUNT(*) FROM biz_patrol_result_media m JOIN biz_patrol_result r ON r.result_id = m.result_id WHERE r.result_code LIKE 'TEST-RES-%';

-- 任务状态分布
SELECT
    '任务状态分布' as category,
    status as status_type,
    COUNT(*) as count
FROM biz_patrol_task
WHERE task_code LIKE 'TEST-TASK-%'
GROUP BY status;

-- 设备状态分布
SELECT
    '设备状态分布' as category,
    status as status_type,
    COUNT(*) as count
FROM biz_usv_device
WHERE device_code LIKE 'TEST-USV-%'
GROUP BY status;