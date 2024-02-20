local api = vim.api

-- Initialize the global variables for the last used options
_G.sync_cache = _G.sync_cache or {}

local function expand_path(path)
    local home = os.getenv("HOME")
    return path:gsub("^~", home)
end

local cache_file = expand_path('~/.vim_sync_cache')

local function load_cache()
    local file = io.open(cache_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        if content ~= "" then
            _G.sync_cache = vim.fn.json_decode(content)
        end
    end
end

local function save_cache()
    local file = io.open(cache_file, "w")
    if file then
        file:write(vim.fn.json_encode(_G.sync_cache))
        file:close()
    end
end

function _G.sync_directory() 
    load_cache()

    -- Get the list of directories in the current working directory
    local directories = vim.fn.split(vim.fn.globpath('.', '*/'), '\n')

    -- Add the top-level directory to the list of directories
    table.insert(directories, 1, '.')

    -- Create a list of options for the user
    local options = {'Select a directory to sync:'}
    for i, directory in ipairs(directories) do
        directories[i] = vim.fn.fnamemodify(directory, ':p')
        table.insert(options, string.format('%d. %s', i, directories[i]))
    end

    -- Ask the user to select a directory
    local selection = vim.fn.inputlist(options)

    -- Check if the user made a valid selection
    if selection < 1 or selection > #directories then
        print('Invalid selection')
        return
    end

    -- Get the selected directory
    local directory = directories[selection]
    _G.last_directory = directory -- Store the selected directory as the last used option

    -- Read the SSH config file and extract the hostnames
    local ssh_config = vim.fn.readfile(expand_path('~/.ssh/config'))
    local hosts = {}
    for _, line in ipairs(ssh_config) do
        if line:match('^Host ') then
            table.insert(hosts, line:match('^Host (.*)'))
        end
    end

    -- Create a list of options for the user
    options = {'Select a remote machine:', '1. Enter a remote manually'}
    for i, host in ipairs(hosts) do
        table.insert(options, string.format('%d. %s', i + 1, host)) -- Note the i + 1 here
    end

    -- Ask the user to select a remote machine
    selection = vim.fn.inputlist(options)

    -- Check if the user made a valid selection
    if selection < 1 or selection > #hosts + 1 then
        print('Invalid selection')
        return
    end

    -- Get the selected remote machine
    local host
    if selection == 1 then
        local default_host = _G.last_host and string.format(' (default: %s)', _G.last_host) or ''
        host = vim.fn.input('Enter the remote machine' .. default_host .. ': ')
    else
        host = hosts[selection - 1] -- Note the selection - 1 here
    end
    _G.last_host = host -- Store the selected host as the last used option

    -- Ask the user to enter the target directory on the remote machine
    local default_target_directory = _G.last_target_directory and string.format(' (default: %s)', _G.last_target_directory) or ''
    local target_directory = vim.fn.input('Enter the target directory on the remote machine' .. default_target_directory .. ': ', _G.last_target_directory)
    _G.last_target_directory = target_directory -- Store the entered target directory as the last used option

    -- Sync the directory to the remote machine
    local rsync_command = string.format('rsync -avz %s %s:%s', directory, host, target_directory)
    print("syncing...")
    print("executing: ", rsync_command)
    local result = os.execute(rsync_command)

    if result then
        print("Sync successful")
        _G.last_host = host
        _G.last_target_directory = target_directory
        save_cache()
    else
        print("Sync failed")
    end
end


vim.cmd('command! FlyAwaySyncToRemote lua _G.sync_directory()')
