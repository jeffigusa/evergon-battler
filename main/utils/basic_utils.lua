local M = {}

local uid = 0
function M.get_uid()
	uid = uid + 1
	return uid
end

function M.delete_uid(a_table, uid)
    local i = M.findIndex(a_table, uid, 'uid', 1)
    assert(i, 'delete_uid('..uid..') could not find item to delete:')
	return table.remove(a_table, i)
end

function M.shallow_copy(a_table)
	local copy = {}
	for k, v in pairs(a_table) do copy[k] = v end
	return copy
end

function M.deep_copy(a_table)
	local serialized = sys.serialize(a_table)
	local copy = sys.deserialize(serialized)
	return copy
end

function M.transfer(from_table, to_table, key_or_i)
	if not from_table[key_or_i] then return false end
	if type(key_or_i) == "number" then
		local v = table.remove(from_table, key_or_i)
		table.insert(to_table, v)
	else
		from_table[key_or_i], to_table[key_or_i] = nil, from_table[key_or_i]
	end
	return true
end

-- splits i_table at index i, with i_table[i] included in the first table: ( {1,2,3}, 2 ) --> {1,2}, {3}
function M.split(i_table, i)
	local r1, r2 = {}, {}
	for j, v in ipairs(i_table) do
		if j <= i then table.insert(r1, v) else table.insert(r2, v) end
	end
	return r1, r2
end

-- returns merged table as a new table. duplicate keys will have value in a_table overwritten by value in b_table
function M.merge(table_of_tables)
	local new_table = {}
	local is_array = true
	for i = 1, #table_of_tables do
		if M.num_key_pairs(table_of_tables[i]) > 0 then
			if is_array and not table_of_tables[i][1] then
				is_array = false
			end
		end
	end
	if is_array then
		for i, n_table in ipairs(table_of_tables) do
			for _i,v in ipairs(n_table) do table.insert(new_table, v) end
		end
	else
		for i, n_table in ipairs(table_of_tables) do
			for k,v in pairs(n_table) do new_table[k] = v end
		end
	end
	return new_table
end

function M.remove_all(i_table, condition_function)
	local to_remove = {}
	for i, v in ipairs(i_table) do
		if condition_function(v) then table.insert(to_remove, 1, i) end
	end
	for _, i in ipairs(to_remove) do
		table.remove(i_table, i)
	end
end

function M.keys_of(a_table)
	local result = {}
	for k, v in pairs(a_table) do table.insert(result, k) end
	return result
end

function M.contains(a_table, value_or_f)
	if hash(type(value_or_f)) == hash('function') then
		for k,v in pairs(a_table) do
			if value_or_f(v) then return true end
		end
	else
		for k,v in pairs(a_table) do
			if v == value_or_f then return true end
		end
	end
	return false
end

function M.num_key_pairs(a_table)
	local num = 0
	for i in pairs(a_table) do num = num + 1 end
	return num
end

function M.isEmpty(a_table)
	if a_table == nil then return true end
	for k, v in pairs(a_table) do return false end
	return true
end

function M.shuffle(a_table)
	local size = #a_table
	for i = size, 2, -1 do --starting from i = size, until i == 2, decrementing i by 1 each loop
		local random_int = math.random(i) --generate a random integer between 1 and i
		a_table[i], a_table[random_int] = a_table[random_int], a_table[i]
	end
end

function M.reverse(i_table)
	local r = {}
	for i, v in ipairs(i_table) do
		table.insert(r, 1, v)
	end
	return r
end

function M.unique_nums(num, min, max)
	assert(num <= max - min + 1, 'not enough unique nums in range')
	local r = {}
	local nums = {}
	for i = min, max do table.insert(nums, i) end M.shuffle(nums)
	for i = 1, num do table.insert(r, nums[i]) end
	return r
end

function M.unique_randoms_from(a_table, num)
	local size = M.num_key_pairs(a_table)
	assert((num or 0) <= size, 'not enough key pairs in table to pull'..num..' random pairs')
	local r = {}
	local indices = M.unique_nums(num, 1, size)
	for _, i in ipairs(indices) do
		local k, v = next(a_table)
		for j = 1, i-1 do
			k, v = next(a_table, k)
		end
		table.insert(r, v)
	end
	return r, indices
end

function M.random_from(a_table)
	local size = M.num_key_pairs(a_table)
	local i_rand = math.random(1, size)
	local i = 0
	for k, v in pairs(a_table) do
		i = i + 1
		if i == i_rand then return v end
	end
end

function M.pick_all(a_table, conditional)
	local r = {}
	for k, v in pairs(a_table) do
		if conditional(v) then table.insert(r, v) end
	end
	return r
end

function M.search(a_table, conditional)
	for k, v in pairs(a_table) do
		if conditional(v) then return v end
	end
end

-- find first key of a value in a table, if not found returns nil
function M.findIndex(a_table, search_value, optional_nested_key, optional_layers_of_nest)
	assert(type(a_table) == 'table' , 'cannot call findIndex on a non-table')
	if optional_nested_key and ( optional_layers_of_nest and optional_layers_of_nest == 0 ) then for k, v in pairs(a_table) do if k == optional_nested_key and v == search_value then return k end end end
	if not optional_nested_key then for k, v in pairs(a_table) do if v == search_value then return k end end end
	if optional_nested_key and optional_layers_of_nest and optional_layers_of_nest > 0 then
		for k, v in pairs(a_table) do
			if type(v) == 'table' then
				local result = M.findIndex(v, search_value, optional_nested_key, optional_layers_of_nest - 1)
				if result then return k end
			end
		end
	end
	return nil
end

function M.remove(a_table, search_value, optional_nested_key, optional_layers_of_nest)
	local i = M.findIndex(a_table, search_value, optional_nested_key, optional_layers_of_nest)
	table.remove(a_table, i)
end

function M.get_distance_from_center( i, total_num, spread_multiplier )
	local half_index = total_num / 2
	local spread_factor = i - half_index - 0.5
	return spread_factor * spread_multiplier
end

function M.get_distance_from_center_grid( i, total_rows, total_cols, spread_multiplier_x, spread_multiplier_y )
	local row = math.ceil(i/total_cols)
	local col = 1 + (i-1) % total_cols
	local half_index_x = total_cols / 2
	local spread_factor_x = col - half_index_x - 0.5
	local half_index_y = total_rows / 2
	local spread_factor_y = -(row - half_index_y - 0.5)
	return {
		x=spread_factor_x * spread_multiplier_x,
		y=spread_factor_y * spread_multiplier_y
	}
end

function M.string_pieces(a_string, delimiter)
	local pieces = {}
	for str in a_string:gmatch('[^'..delimiter..']+') do
		table.insert(pieces, str)
	end
	return pieces
end

function M.occurences(a_table, item_or_qualifier_f, key_if_nested)
	local num_occurences = 0
	if key_if_nested then
		for k, nested_table in pairs(a_table) do
			for nested_k, nested_v in pairs(nested_table) do
				if nested_k == key_if_nested and nested_v == item_or_qualifier_f then
					num_occurences = num_occurences + 1
				end
			end
		end
	elseif type(item_or_qualifier_f) == 'function' then
		for k, v in pairs(a_table) do
			if item_or_qualifier_f(v) then num_occurences = num_occurences + 1 end
		end
	else
		for k, v in pairs(a_table) do
			if v == item_or_qualifier_f then num_occurences = num_occurences + 1 end
		end
	end
	return num_occurences
end

-- returns 1 --> 'a', 2 --> 'b', etc
function M.num_to_letter(num)
	local alphabet = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}
	return alphabet[num]
end

-- uppercases first letter of str, returned as new string
function M.uppercase_first(str)
	local first_letter = str:sub(1,1):upper()
	local remaining = str:sub(2,-1)
	return first_letter..remaining
end

function M.remove_blanks(i_table)
	local i_to_remove = {}
	for i, v in ipairs(i_table) do
		if type(v) == 'table' and M.isEmpty(v) or v==nil then
			table.insert(i_to_remove, i)
		end
	end
	M.reverse(i_to_remove)
	for _, i in ipairs(i_to_remove) do
		table.remove(i_table, i)
	end
end

-- returns stack. required to call stack:do_next() to start the sequence as well as at the end of each function (except for last f).
function M.do_sequentially(functions)
	local stack = {
		fs = functions,
		do_next = function(self)
			if #self.fs <= 0 then return end
			local f = table.remove(self.fs, 1)
			f()
		end
	}
	return stack
end


return M