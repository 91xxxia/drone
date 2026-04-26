package com.ruoyi.web.controller.drone;

import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.domain.BizPatrolTask;
import com.ruoyi.system.service.IBizPatrolTaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/drone/task")
public class BizPatrolTaskController extends BaseController
{
    @Autowired
    private IBizPatrolTaskService taskService;

    @PreAuthorize("@ss.hasPermi('drone:task:list')")
    @GetMapping("/list")
    public TableDataInfo list(BizPatrolTask query)
    {
        startPage();
        List<BizPatrolTask> list = taskService.selectBizPatrolTaskList(query);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('drone:task:query')")
    @GetMapping("/{taskId}")
    public AjaxResult getInfo(@PathVariable Long taskId)
    {
        return success(taskService.selectBizPatrolTaskById(taskId));
    }

    @Log(title = "巡防任务", businessType = BusinessType.INSERT)
    @PreAuthorize("@ss.hasPermi('drone:task:add')")
    @PostMapping
    public AjaxResult add(@RequestBody BizPatrolTask task)
    {
        return toAjax(taskService.insertBizPatrolTask(task, getUsername()));
    }

    @Log(title = "巡防任务", businessType = BusinessType.UPDATE)
    @PreAuthorize("@ss.hasPermi('drone:task:edit')")
    @PutMapping
    public AjaxResult edit(@RequestBody BizPatrolTask task)
    {
        task.setUpdateBy(getUsername());
        return toAjax(taskService.updateBizPatrolTask(task));
    }

    @Log(title = "巡防任务", businessType = BusinessType.UPDATE)
    @PreAuthorize("@ss.hasPermi('drone:task:start')")
    @PutMapping("/start/{taskId}")
    public AjaxResult start(@PathVariable Long taskId)
    {
        return toAjax(taskService.startTask(taskId, getUsername()));
    }

    @Log(title = "巡防任务", businessType = BusinessType.UPDATE)
    @PreAuthorize("@ss.hasPermi('drone:task:finish')")
    @PutMapping("/finish/{taskId}")
    public AjaxResult finish(@PathVariable Long taskId)
    {
        return toAjax(taskService.finishTask(taskId, getUsername()));
    }

    @Log(title = "巡防任务", businessType = BusinessType.UPDATE)
    @PreAuthorize("@ss.hasPermi('drone:task:cancel')")
    @PutMapping("/cancel/{taskId}")
    public AjaxResult cancel(@PathVariable Long taskId)
    {
        return toAjax(taskService.cancelTask(taskId, getUsername()));
    }

    @Log(title = "巡防任务", businessType = BusinessType.DELETE)
    @PreAuthorize("@ss.hasPermi('drone:task:remove')")
    @DeleteMapping("/{taskIds}")
    public AjaxResult remove(@PathVariable Long[] taskIds)
    {
        return toAjax(taskService.deleteBizPatrolTaskByIds(taskIds));
    }
}
