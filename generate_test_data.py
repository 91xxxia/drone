#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
无人机/无人船测试数据生成器（Python版本）
使用Python生成测试数据，避免SQL语法问题
"""

import mysql.connector
import random
import datetime
from decimal import Decimal

class TestDataGenerator:
    def __init__(self, host, user, password, database):
        self.host = host
        self.user = user
        self.password = password
        self.database = database
        self.connection = None
        self.cursor = None

    def connect(self):
        """连接到数据库"""
        try:
            self.connection = mysql.connector.connect(
                host=self.host,
                user=self.user,
                password=self.password,
                database=self.database,
                charset='utf8mb4'
            )
            self.cursor = self.connection.cursor()
            print("数据库连接成功！")
            return True
        except Exception as e:
            print(f"数据库连接失败: {e}")
            return False

    def cleanup_old_data(self):
        """清理旧的测试数据"""
        print("正在清理旧的测试数据...")

        cleanup_queries = [
            "DELETE FROM biz_patrol_result_media WHERE result_id IN (SELECT result_id FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES-%')",
            "DELETE FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES-%'",
            "DELETE FROM biz_patrol_task_log WHERE task_id IN (SELECT task_id FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK-%')",
            "DELETE FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK-%'",
            "DELETE FROM biz_patrol_route_point WHERE route_id IN (SELECT route_id FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%')",
            "DELETE FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%'",
            "DELETE FROM biz_usv_device WHERE device_code LIKE 'TEST-USV-%'"
        ]

        for query in cleanup_queries:
            try:
                self.cursor.execute(query)
            except Exception as e:
                print(f"清理数据时出错: {e}")

        self.connection.commit()
        print("旧数据清理完成！")

    def generate_devices(self):
        """生成设备数据"""
        print("正在生成设备数据...")

        devices = [
            ('TEST-USV-001', '测试无人船-01', 'USV-X1', 180, '4K/30fps 云台', '张三', 'normal', '测试设备-01'),
            ('TEST-USV-002', '测试无人船-02', 'USV-X2', 150, '1080P 夜视', '李四', 'in_task', '测试设备-02'),
            ('TEST-USV-003', '测试无人船-03', 'USV-Pro', 210, '4K/60fps 双目', '王五', 'normal', '测试设备-03'),
            ('TEST-USV-004', '测试无人船-04', 'USV-Maint', 120, '1080P', '赵六', 'maintenance', '测试设备-04'),
            ('TEST-USV-005', '测试无人船-05', 'USV-Edge', 160, '1080P 广角', '钱七', 'offline', '测试设备-05'),
            ('TEST-USV-006', '测试无人船-06', 'USV-X1', 190, '4K/30fps 云台', '孙八', 'normal', '测试设备-06'),
            ('TEST-USV-007', '测试无人船-07', 'USV-X2', 140, '1080P 夜视', '周九', 'normal', '测试设备-07'),
            ('TEST-USV-008', '测试无人船-08', 'USV-Pro', 200, '4K/60fps 双目', '吴十', 'in_task', '测试设备-08'),
            ('TEST-USV-009', '测试无人船-09', 'USV-Maint', 130, '1080P', '张三', 'normal', '测试设备-09'),
            ('TEST-USV-010', '测试无人船-10', 'USV-Edge', 170, '1080P 广角', '李四', 'maintenance', '测试设备-10')
        ]

        query = """
        INSERT INTO biz_usv_device
        (device_code, device_name, device_model, endurance_minutes, camera_spec, owner_name, status, remark, create_by, create_time)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'admin', NOW())
        """

        self.cursor.executemany(query, devices)
        self.connection.commit()

        # 获取设备ID映射
        self.cursor.execute("SELECT device_id, device_code FROM biz_usv_device WHERE device_code LIKE 'TEST-USV-%'")
        self.device_map = {code: id for id, code in self.cursor.fetchall()}
        print(f"已生成 {len(devices)} 台设备")

    def generate_routes(self):
        """生成航线数据"""
        print("正在生成航线数据...")

        routes = [
            ('TEST-航线A-沿江巡防', 45, Decimal('25.00'), '测试航线A'),
            ('TEST-航线B-港区巡防', 35, Decimal('20.00'), '测试航线B'),
            ('TEST-航线C-闸口巡防', 55, Decimal('30.00'), '测试航线C'),
            ('TEST-航线D-备用巡防', 25, Decimal('18.00'), '测试航线D'),
            ('TEST-航线E-快速通道', 30, Decimal('22.00'), '测试航线E')
        ]

        query = """
        INSERT INTO biz_patrol_route
        (route_name, est_duration_minutes, altitude, remark, create_by, create_time)
        VALUES (%s, %s, %s, %s, 'admin', NOW())
        """

        self.cursor.executemany(query, routes)
        self.connection.commit()

        # 获取航线ID映射
        self.cursor.execute("SELECT route_id, route_name FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%'")
        self.route_map = {name: id for id, name in self.cursor.fetchall()}
        print(f"已生成 {len(routes)} 条航线")

    def generate_route_points(self):
        """生成航点数据"""
        print("正在生成航点数据...")

        # 基础坐标
        base_coords = {
            'TEST-航线A-沿江巡防': [(112.9382100, 28.2284900), (112.9421100, 28.2312000), (112.9478000, 28.2339100), (112.9531000, 28.2357000)],
            'TEST-航线B-港区巡防': [(112.9203000, 28.2181000), (112.9257000, 28.2204000), (112.9319000, 28.2226000)],
            'TEST-航线C-闸口巡防': [(112.9602000, 28.2401000), (112.9654000, 28.2427000), (112.9710000, 28.2461000), (112.9753000, 28.2490000), (112.9801000, 28.2516000)],
            'TEST-航线D-备用巡防': [(112.9100000, 28.2100000), (112.9135000, 28.2123000), (112.9172000, 28.2141000)],
            'TEST-航线E-快速通道': [(112.9850000, 28.2550000), (112.9885000, 28.2573000), (112.9922000, 28.2591000)]
        }

        points = []
        for route_name, coords in base_coords.items():
            route_id = self.route_map[route_name]
            for seq, (lng, lat) in enumerate(coords, 1):
                points.append((route_id, seq, lng, lat))

        query = "INSERT INTO biz_patrol_route_point (route_id, seq, lng, lat) VALUES (%s, %s, %s, %s)"
        self.cursor.executemany(query, points)
        self.connection.commit()
        print(f"已生成 {len(points)} 个航点")

    def generate_tasks(self):
        """生成任务数据"""
        print("正在生成任务数据...")

        # 任务类型
        task_types = ['日常巡防', '专项检测', '紧急巡查', '定期维护', '数据收集']
        executors = ['张三', '李四', '王五', '赵六', '钱七', '孙八', '周九', '吴十']

        tasks = []
        for i in range(1, 21):  # 生成20个任务
            task_code = f'TEST-TASK-{i:04d}'
            task_type = random.choice(task_types)
            executor = random.choice(executors)
            device_id = random.choice(list(self.device_map.values()))
            route_id = random.choice(list(self.route_map.values()))

            # 随机状态
            status_rand = random.random()
            if status_rand < 0.25:
                status = 'pending'
                progress = 0
                start_time = None
                end_time = None
                planned_start = datetime.datetime.now() + datetime.timedelta(days=random.randint(1, 7))
            elif status_rand < 0.5:
                status = 'running'
                progress = random.randint(20, 90)
                start_time = datetime.datetime.now() - datetime.timedelta(hours=random.randint(1, 48))
                end_time = None
                planned_start = start_time - datetime.timedelta(hours=1)
            elif status_rand < 0.8:
                status = 'completed'
                progress = 100
                start_time = datetime.datetime.now() - datetime.timedelta(hours=random.randint(2, 72))
                end_time = start_time + datetime.timedelta(minutes=random.randint(30, 120))
                planned_start = start_time - datetime.timedelta(hours=1)
            else:
                status = 'canceled'
                progress = random.randint(0, 50)
                start_time = datetime.datetime.now() - datetime.timedelta(hours=random.randint(2, 48)) if random.random() > 0.5 else None
                end_time = start_time + datetime.timedelta(hours=1) if start_time else datetime.datetime.now() - datetime.timedelta(hours=random.randint(1, 24))
                planned_start = (start_time or end_time) - datetime.timedelta(hours=1)

            task_desc = f'测试任务描述-{i:03d}'

            tasks.append((
                task_code, f'测试任务-{i:03d}-{task_type}', executor, planned_start, task_desc,
                device_id, route_id, status, progress, start_time, end_time, 'admin'
            ))

        query = """
        INSERT INTO biz_patrol_task
        (task_code, task_name, executor, planned_start_time, task_desc, device_id, route_id,
         status, progress, start_time, end_time, create_by, create_time)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
        """

        self.cursor.executemany(query, tasks)
        self.connection.commit()

        # 获取任务ID映射
        self.cursor.execute("SELECT task_id, task_code FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK-%'")
        self.task_map = {code: id for id, code in self.cursor.fetchall()}
        print(f"已生成 {len(tasks)} 个任务")

    def generate_task_logs(self):
        """生成任务日志"""
        print("正在生成任务日志...")

        logs = []

        for task_code, task_id in self.task_map.items():
            # 添加创建日志
            logs.append((task_id, None, 'pending', 'admin',
                        datetime.datetime.now() - datetime.timedelta(minutes=random.randint(30, 120)), '任务创建'))

            # 获取任务状态信息
            self.cursor.execute("SELECT status, start_time, end_time FROM biz_patrol_task WHERE task_id = %s", (task_id,))
            status, start_time, end_time = self.cursor.fetchone()

            # 添加开始日志（如果任务已开始）
            if status in ['running', 'completed'] and start_time:
                logs.append((task_id, 'pending', 'running', 'admin', start_time, '开始任务'))

            # 添加完成日志（如果任务已完成）
            if status == 'completed' and end_time:
                logs.append((task_id, 'running', 'completed', 'admin', end_time, '任务完成'))

            # 添加取消日志（如果任务已取消）
            if status == 'canceled' and end_time:
                from_status = 'running' if start_time else 'pending'
                logs.append((task_id, from_status, 'canceled', 'admin', end_time, '任务取消'))

        query = "INSERT INTO biz_patrol_task_log (task_id, from_status, to_status, operate_by, operate_time, remark) VALUES (%s, %s, %s, %s, %s, %s)"
        self.cursor.executemany(query, logs)
        self.connection.commit()
        print(f"已生成 {len(logs)} 条任务日志")

    def generate_results(self):
        """生成结果数据"""
        print("正在生成结果数据...")

        # 获取已完成的任务
        self.cursor.execute("""
        SELECT t.task_id, t.task_name, t.device_id, d.device_name, t.route_id, r.route_name,
               t.start_time, t.end_time, t.executor
        FROM biz_patrol_task t
        JOIN biz_usv_device d ON d.device_id = t.device_id
        JOIN biz_patrol_route r ON r.route_id = t.route_id
        WHERE t.task_code LIKE 'TEST-TASK-%' AND t.status = 'completed'
        """)

        completed_tasks = self.cursor.fetchall()
        results = []

        for i, (task_id, task_name, device_id, device_name, route_id, route_name, start_time, end_time, executor) in enumerate(completed_tasks, 1):
            duration = int((end_time - start_time).total_seconds() / 60) if start_time and end_time else 60

            overviews = [
                '本次巡防任务正常完成，航线覆盖完整，未出现突发风险。',
                '本次巡防任务完成，数据采集完整，系统运行正常。',
                '本次巡防任务顺利完成，各项指标符合预期。'
            ]

            findings = [
                '未发现异常情况。',
                '发现一处疑似漂浮物，已记录坐标并复核。',
                '发现船只异常停靠，已通知相关部门。'
            ]

            handlings = [
                '无需特殊处理，继续正常监控。',
                '已通知值班人员人工复核，确认无安全隐患。',
                '已联系相关部门处理，建议后续加强监控。'
            ]

            result = (
                f'TEST-RES-{i:03d}', task_id, task_name, device_id, device_name, route_id, route_name,
                duration, end_time, executor,
                random.choice(overviews), random.choice(findings), random.choice(handlings),
                f'测试数据：任务ID {task_id} 的自动生成结果',
                'admin'
            )
            results.append(result)

        query = """
        INSERT INTO biz_patrol_result
        (result_code, task_id, task_name, device_id, device_name, route_id, route_name,
         duration_minutes, completed_time, executor, overview, findings, handling, remark, create_by, create_time)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
        """

        self.cursor.executemany(query, results)
        self.connection.commit()

        # 获取结果ID映射
        self.cursor.execute("SELECT result_id, result_code FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES-%'")
        self.result_map = {code: id for id, code in self.cursor.fetchall()}
        print(f"已生成 {len(results)} 个结果")

    def generate_result_media(self):
        """生成结果媒体数据"""
        print("正在生成结果媒体数据...")

        media = []
        tags = ['漂浮物', '船只', '人员', '障碍物', '正常']

        for result_code, result_id in self.result_map.items():
            # 每个结果生成1-3个媒体文件
            num_media = random.randint(1, 3)
            for j in range(num_media):
                tag = random.choice(tags)
                x = random.randint(50, 300)
                y = random.randint(50, 300)
                w = random.randint(80, 200)
                h = random.randint(60, 180)

                bbox = f'{{"x":{x},"y":{y},"w":{w},"h":{h}}}'
                file_url = f'/profile/upload/test/{result_code.lower()}_{chr(97+j)}.jpg'

                media.append((result_id, file_url, tag, bbox, 'admin'))

        query = "INSERT INTO biz_patrol_result_media (result_id, file_url, ai_tag, bbox_json, create_by, create_time) VALUES (%s, %s, %s, %s, %s, NOW())"
        self.cursor.executemany(query, media)
        self.connection.commit()
        print(f"已生成 {len(media)} 个媒体文件")

    def update_device_status(self):
        """更新设备状态以匹配任务状态"""
        print("正在更新设备状态...")

        # 将执行中任务对应的设备状态更新为in_task
        self.cursor.execute("""
        UPDATE biz_usv_device d
        JOIN biz_patrol_task t ON t.device_id = d.device_id AND t.status = 'running'
        SET d.status = 'in_task', d.update_by = 'admin', d.update_time = NOW()
        WHERE d.device_code LIKE 'TEST-USV-%'
        """)

        # 将已完成任务对应的设备状态更新为normal
        self.cursor.execute("""
        UPDATE biz_usv_device d
        JOIN biz_patrol_task t ON t.device_id = d.device_id AND t.status = 'completed'
        SET d.status = 'normal', d.update_by = 'admin', d.update_time = NOW()
        WHERE d.device_code LIKE 'TEST-USV-%' AND d.status != 'in_task'
        """)

        self.connection.commit()
        print("设备状态更新完成")

    def show_statistics(self):
        """显示统计信息"""
        print("\n=== 数据生成统计 ===")

        queries = [
            ("设备数量", "SELECT COUNT(*) FROM biz_usv_device WHERE device_code LIKE 'TEST-USV-%'"),
            ("航线数量", "SELECT COUNT(*) FROM biz_patrol_route WHERE route_name LIKE 'TEST-航线%'"),
            ("任务数量", "SELECT COUNT(*) FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK-%'"),
            ("结果数量", "SELECT COUNT(*) FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES-%'"),
            ("媒体数量", "SELECT COUNT(*) FROM biz_patrol_result_media WHERE result_id IN (SELECT result_id FROM biz_patrol_result WHERE result_code LIKE 'TEST-RES-%')")
        ]

        for name, query in queries:
            self.cursor.execute(query)
            count = self.cursor.fetchone()[0]
            print(f"{name}: {count}")

        # 任务状态分布
        print("\n任务状态分布:")
        self.cursor.execute("SELECT status, COUNT(*) FROM biz_patrol_task WHERE task_code LIKE 'TEST-TASK-%' GROUP BY status")
        for status, count in self.cursor.fetchall():
            print(f"  {status}: {count}")

        # 设备状态分布
        print("\n设备状态分布:")
        self.cursor.execute("SELECT status, COUNT(*) FROM biz_usv_device WHERE device_code LIKE 'TEST-USV-%' GROUP BY status")
        for status, count in self.cursor.fetchall():
            print(f"  {status}: {count}")

    def generate_all(self):
        """生成所有测试数据"""
        if not self.connect():
            return

        try:
            self.cleanup_old_data()
            self.generate_devices()
            self.generate_routes()
            self.generate_route_points()
            self.generate_tasks()
            self.generate_task_logs()
            self.generate_results()
            self.generate_result_media()
            self.update_device_status()
            self.show_statistics()
            print("\n✅ 测试数据生成完成！")

        except Exception as e:
            print(f"生成数据时出错: {e}")
        finally:
            if self.cursor:
                self.cursor.close()
            if self.connection:
                self.connection.close()

if __name__ == "__main__":
    # 配置数据库连接
    generator = TestDataGenerator(
        host="localhost",      # 修改为你的数据库主机
        user="root",           # 修改为你的数据库用户名
        password="password",    # 修改为你的数据库密码
        database="drone"       # 修改为你的数据库名
    )

    print("🚀 开始生成无人机/无人船测试数据...")
    generator.generate_all()