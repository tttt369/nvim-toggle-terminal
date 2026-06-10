local M = {}
M.file2term = {}
M.height = 13

local function open_terminal()
    local file_buf = vim.api.nvim_get_current_buf()

    vim.cmd('botright ' .. M.height .. 'split | terminal')

    local term_buf = vim.api.nvim_get_current_buf()

    M.file2term[file_buf] = term_buf
end

local function get_win_obj_buf()
    local current_tab = vim.api.nvim_get_current_tabpage()
    local win_list = vim.api.nvim_tabpage_list_wins(current_tab) -- Get all windows from current tab.

    -- Convert the currently displayed buff_id to a boolean element.
    local win_obj_buf = {}
    for _, win in pairs(win_list) do
        local buf = vim.api.nvim_win_get_buf(win)
        win_obj_buf[buf] = true
    end

    return win_obj_buf
end

function M.toggle_terminal()
    local win_obj_buf = get_win_obj_buf()
    if (next(M.file2term) == nil) then
        open_terminal()
        return
    end

    -- Check all terminal window in current tabs.
    local term_buf
    for _, buf in pairs(M.file2term) do
        if (win_obj_buf[buf]) then
            term_buf = buf
            break
        end
    end

    -- Find the window thats initiate the terminal window.
    local past_term_buf, file_buf
    for buf, _ in pairs(win_obj_buf) do
        if (term_buf) then
            break
        end

        if (M.file2term[buf]) then
            past_term_buf = M.file2term[buf]
            file_buf = buf
            break
        end
    end

    -- If there is terminal window.
    if (term_buf) then
        for _, v in pairs(vim.fn.win_findbuf(term_buf)) do
            M.height = vim.api.nvim_win_get_height(v)
            vim.api.nvim_win_hide(v)
        end
    -- If there is window thats initiate the terminal.
    elseif (past_term_buf) then
        if vim.fn.bufexists(past_term_buf) == 0 then
            M.file2term[file_buf] = nil
            open_terminal()
            return
        end
        vim.cmd('botright ' .. M.height .. 'split | buffer ' .. past_term_buf)
    else
        open_terminal()
    end
end

-- Check if the terminal and files are in the current tab
function M.change_to_file_dir()
    local win_obj_buf = get_win_obj_buf()
    for file, term in pairs(M.file2term) do
        if (win_obj_buf[file] and win_obj_buf[term]) then
            vim.fn.chansend(vim.b[term].terminal_job_id, "cd " .. vim.fn.fnamemodify(vim.fn.bufname(file), ":p:h") .. "\n")
            break
        end
    end
end

return M
