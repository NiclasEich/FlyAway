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

function _G.sync_directory(sync_type)
    load_cache()

    -- Get the list of directories in the current working directory
    local directories = vim.fn.split(vim.fn.globpath('.', '*/'), '\n')

    -- Add the top-level directory to the list of directories
    table.insert(directories, 1, '.')

    -- Create a list of options for the user
    local options = {'Select a directory to sync:', '1. Enter a directory manually'}
    for i, directory in ipairs(directories) do
        directories[i] = vim.fn.fnamemodify(directory, ':p')
        table.insert(options, string.format('%d. %s', 1+i, directories[i]))
    end
    -- Ask the user to select a directory
    local selection = vim.fn.inputlist(options)

    -- If the user selected the manual entry option, ask for the manual entry
    if selection == 1 then
        directory = vim.fn.input('Enter the directory to sync: ')
    else
        directory = directories[selection - 1]
    end
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
    options = {'Select a remote:', '1. Enter a remote manually'}
    for i, host in ipairs(hosts) do
        table.insert(options, string.format('%d. %s', i + 1, host)) -- Note the i + 1 here
    end

    -- Ask the user to select a remote machine
    selection = vim.fn.inputlist(options)

    -- Check if the user made a valid selection
    if selection == 1 then
        host = vim.fn.input('Enter the target host: ')
    else
        host = hosts[selection -1]
    end

    -- Get the target host and directory from the cache
    local cached_target_directory = _G.sync_cache[directory] and _G.sync_cache[directory].target_directory or ""

    -- Get the target host and directory from the user
    local target_directory = vim.fn.input('Enter the remot directory: ', cached_target_directory)

    -- Determine the rsync command based on the sync_type
    local rsync_command
    if sync_type == 'pull' then
        rsync_command = string.format('rsync -avz %s:%s/ %s', host, target_directory, directory)
    else -- default to 'push'
        rsync_command = string.format('rsync -avz %s %s:%s/', directory, host, target_directory)
    end

    local result = vim.fn.system(rsync_command)

    if vim.v.shell_error then
        print("Sync successful")
        _G.sync_cache[directory] = {host = host, target_directory = target_directory}
        save_cache()
    else
        print("Sync failed")
    end
    vim.cmd('redraw!')
end

-- Create a Vim command that calls the sync_directory function
vim.cmd([[
    command! -nargs=1 -complete=customlist,SyncDirectoryComplete FlyAwaySync call luaeval('_G.sync_directory(_A)', <f-args>)

    function! SyncDirectoryComplete(ArgLead, CmdLine, CursorPos)
        let l:options = ['pull', 'push']
        return filter(l:options, 'v:val =~ "^' . a:ArgLead . '"')
    endfunction
]])
