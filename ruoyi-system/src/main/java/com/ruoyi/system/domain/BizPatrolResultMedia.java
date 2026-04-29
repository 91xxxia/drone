package com.ruoyi.system.domain;

public class BizPatrolResultMedia
{
    private Long mediaId;

    private Long resultId;

    private String fileUrl;

    private String aiTag;

    private String bboxJson;

    public Long getMediaId()
    {
        return mediaId;
    }

    public void setMediaId(Long mediaId)
    {
        this.mediaId = mediaId;
    }

    public Long getResultId()
    {
        return resultId;
    }

    public void setResultId(Long resultId)
    {
        this.resultId = resultId;
    }

    public String getFileUrl()
    {
        return fileUrl;
    }

    public void setFileUrl(String fileUrl)
    {
        this.fileUrl = fileUrl;
    }

    public String getAiTag()
    {
        return aiTag;
    }

    public void setAiTag(String aiTag)
    {
        this.aiTag = aiTag;
    }

    public String getBboxJson()
    {
        return bboxJson;
    }

    public void setBboxJson(String bboxJson)
    {
        this.bboxJson = bboxJson;
    }
}