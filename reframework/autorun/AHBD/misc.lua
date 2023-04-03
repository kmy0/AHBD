local misc = {}

function misc.table_remove(t, fn_keep)
    local i, j, n = 1, 1, #t;
    while i <= n do
        if (fn_keep(t, i, j)) then
            local k = i
            repeat
                i = i + 1;
            until i>n or not fn_keep(t, i, j+i-k)
            --if (k ~= j) then
                table.move(t,k,i-1,j);
            --end
            j = j + i - k;
        end
        i = i + 1;
    end
    table.move(t,n+1,n+n-j+1,j);
    return t;
end

function misc.table_contains(list, x)
    for _, v in pairs(list) do
        if v == x then
            return true
        end
    end
    return false
end

function misc.table_copy(t)
    local newtable = {}
    for k,v in pairs(t) do
        newtable[k] = v
    end
    return newtable
end

function misc.add_count(t, k)
    local count = t[k]
    if count then
        t[k] = count + 1
    else
        t[k] = 1
    end
    return t
end

function misc.join_table(t)
    local str = nil
    for k,v in pairs(t) do
        local l = k .. ' ' .. v
        if not str then
            str = l .. '\n'
        else
            str = str .. l
        end
    end
    return str
end

function misc.get_nested_table(t, ...)
    local keys = { ... }

    for i=1, #keys do
        local key = keys[i]

        if not t[key] then
            t[key] = {}
        end

        t = t[key]
    end

    return t
end

function misc.set_nested_value(t, key, value, ...)
    local t = misc.get_nested_table(t, ...)
    t[key] = value
end

function misc.table_deep_copy(original, copies)
    copies = copies or {};
    local original_type = type(original);
    local copy;
    if original_type == "table" then
        if copies[original] then
            copy = copies[original];
        else
            copy = {};
            copies[original] = copy;
            for original_key, original_value in next, original, nil do
                copy[misc.table_deep_copy(original_key, copies)] = misc.table_deep_copy(original_value
                    ,
                    copies);
            end
            setmetatable(copy,
                misc.table_deep_copy(getmetatable(original)
                    , copies));
        end
    else -- number, string, boolean, etc
        copy = original;
    end
    return copy;
end

function misc.table_merge(...)
    local tables_to_merge = { ... };
    assert(#tables_to_merge > 1, "There should be at least two tables to merge them");

    for key, table in ipairs(tables_to_merge) do
        assert(type(table) == "table", string.format("Expected a table as function parameter %d", key));
    end

    local result = misc.table_deep_copy(tables_to_merge[1]);

    for i = 2, #tables_to_merge do
        local from = tables_to_merge[i];
        for key, value in pairs(from) do
            if type(value) == "table" then
                result[key] = result[key] or {};
                assert(type(result[key]) == "table", string.format("Expected a table: '%s'", key));
                result[key] = misc.table_merge(result[key], value);
            else
                result[key] = value;
            end
        end
    end

    return result;
end

function misc.starts_with(str, pattern)
   return string.sub(str, 1, string.len(pattern)) == pattern
end

return misc
