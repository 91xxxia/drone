package com.ruoyi.web.controller.drone;

import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.system.domain.BizPatrolResult;
import com.ruoyi.system.service.IBizPatrolResultService;
import jakarta.servlet.http.HttpServletResponse;
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
@RequestMapping("/drone/result")
public class BizPatrolResultController extends BaseController
{
    @Autowired
    private IBizPatrolResultService resultService;

    @PreAuthorize("@ss.hasPermi('drone:result:list')")
    @GetMapping("/list")
    public TableDataInfo list(BizPatrolResult query)
    {
        startPage();
        List<BizPatrolResult> list = resultService.selectBizPatrolResultList(query);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('drone:result:detail')")
    @GetMapping("/{resultId}")
    public AjaxResult getInfo(@PathVariable Long resultId)
    {
        return success(resultService.selectBizPatrolResultById(resultId));
    }

    @Log(title = "巡防结果", businessType = BusinessType.EXPORT)
    @PreAuthorize("@ss.hasPermi('drone:result:export')")
    @PostMapping("/export")
    public void export(HttpServletResponse response, BizPatrolResult query)
    {
        List<BizPatrolResult> list = resultService.selectBizPatrolResultList(query);
        ExcelUtil<BizPatrolResult> util = new ExcelUtil<>(BizPatrolResult.class);
        util.exportExcel(response, list, "巡防结果数据");
    }

    @Log(title = "巡防结果", businessType = BusinessType.UPDATE)
    @PreAuthorize("@ss.hasPermi('drone:result:edit')")
    @PutMapping
    public AjaxResult edit(@RequestBody BizPatrolResult result)
    {
        result.setUpdateBy(getUsername());
        return toAjax(resultService.updateBizPatrolResult(result));
    }

    @Log(title = "巡防结果", businessType = BusinessType.DELETE)
    @PreAuthorize("@ss.hasPermi('drone:result:remove')")
    @DeleteMapping("/{resultIds}")
    public AjaxResult remove(@PathVariable Long[] resultIds)
    {
        return toAjax(resultService.deleteBizPatrolResultByIds(resultIds));
    }
}
