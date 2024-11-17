--function split(str,reps)
--    local resultStrList = {}
--    string.gsub(str,'[^'..reps..']+',function (w)
--        table.insert(resultStrList,w)
--    end)
--    return resultStrList
--end

function set_index(record)
    prefix = "logstash-uat"
    if record["kubernetes"] ~= nil then
        if record["kubernetes"]["labels"]["app"] ~= nil then
            project_initial_name = record["kubernetes"]["labels"]["app"]
            project_name, _ = string.gsub(project_initial_name, '-', '_')
            record["es_index"] = project_name
            return record
        end
    end
    return record
end;

function getPrevday(interval)
    local offset = 60 *60 * 24 * interval
    --指定的时间+时间偏移量  
    local newTime = os.date("*t", dt1 - tonumber(offset))
    return newTime
end

--os_date = os.date("%Y-%m-%dT%H:%M:%S.%NZ")
local utc_date = os.time() + 28800
local hk_date = os.date("%Y-%m-%dT00:00:00.000Z", utc_date)
print(hk_date)

--local timestamp = os.clock()
--print(timestamp)

--record = {kubernetes={labels={app="public-rex-game-center"}}}
--x = set_index(record)
--for k,v in pairs(x) do
--    print(k,v)
--end

--n = ''
--data = split(s,'-')
--for i=1,#(data) do
--    print(data[i])
--end
