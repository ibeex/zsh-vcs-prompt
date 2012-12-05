###############################################################################
#
#  VCS INFO
#
#  How to install
#     source path/to/zshrc.sh
#
#     # an example prompt
#     RPROMPT='$(vcs_super_info)'
#
###############################################################################

# Using python script (gitstatus.py)
if [ -z "$ZSH_VCS_PROMPT_USING_PYTHON" ];then
    ZSH_VCS_PROMPT_USING_PYTHON='true'
fi

#
# Default values for the appearance of the prompt.
# Configure at will.
#
# git status symbol
VCS_SIGIL=${VCS_SIGIL:-'∇ '}
VCS_ACTION_SEPARATOR=${VCS_ACTION_SEPARATOR:-':'}
VCS_STAGED_SIGIL=${VCS_STAGED_SIGIL:-'● '}
VCS_UNSTAGED_SIGIL=${VCS_UNSTAGED_SIGIL:-'✚ '}
VCS_UNTRACKED_SIGIL=${VCS_UNTRACKED_SIGIL:-'… '}
VCS_CONFLICTS_SIGIL=${VCS_CONFLICTS_SIGIL:-'✖ '}
VCS_STASHED_SIGIL=${VCS_STASHED_SIGIL:-'⚑'}
VCS_CLEAN_SIGIL=${VCS_CLEAN_SIGIL:-'✔ '}
VCS_AHEAD_SIGIL=${VCS_AHEAD_SIGIL:-'↑ '}
VCS_BEHIND_SIGIL=${VCS_BEHIND_SIGIL:-'↓ '}

# color settings
VCS_NAME_COLOR=${VCS_NAME_COLOR:-'%{%B%F{green}%}'}
VCS_NAME_COLOR_USING_PYTHON=${VCS_NAME_COLOR_USING_PYTHON:-'%{%F{yellow}%}'}
VCS_BRANCH_COLOR=${VCS_BRANCH_COLOR:-'%{%B%F{red}%}'}
VCS_ACTION_COLOR=${VCS_ACTION_COLOR:-'%{%B%F{red}%}'}
VCS_REMOTE_COLOR=${VCS_REMOTE_COLOR:-}
VCS_STAGED_COLOR=${VCS_STAGED_COLOR:-'%{%F{blue}%}'}
VCS_UNSTAGED_COLOR=${VCS_UNSTAGED_COLOR:-'%{%F{yellow}%}'}
VCS_UNTRACKED_COLOR=${VCS_UNTRACKED_COLOR:-}
VCS_CONFLICTS_COLOR=${VCS_CONFLICTS_COLOR:-'%{%F{red}%}'}
VCS_STASHED_COLOR=${VCS_STASHED_COLOR:-'%{%F{cyan}%}'}
VCS_CLEAN_COLOR=${VCS_CLEAN_COLOR:-'%{%F{green}%}'}

# Exe directory
ZSH_VCS_PROMPT_DIR=$(cd $(dirname $0) && pwd)

#
# VCS_INFO
#  http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#SEC273
#  https://github.com/olivierverdier/zsh-git-prompt
#  http://d.hatena.ne.jp/mollifier/20100906/p1
#  http://d.hatena.ne.jp/yuroyoro/20110219/1298089409
#  http://d.hatena.ne.jp/pasela/20110216/git_not_pushed
#  http://liosk.blog103.fc2.com/blog-entry-209.html
#
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn hg bzr

# The maximum number of vcs_info_msg_*_ variables.
zstyle ':vcs_info:*' max-exports 7

# To be enable check-for-changes with hg
zstyle ':vcs_info:hg:*' get-revision true
zstyle ':vcs_info:hg:*' use-simple true

#
# In normal formats and actionformats the following replacements are done:
#   %s : The VCS in use (git, hg, svn, etc.).
#   %b : Information about the current branch.
#   %a : An identifier that describes the action. Only makes sense in actionformats.
#   %r : The repository name. If %R is /foo/bar/repoXY, %r is repoXY.
#   %c : The string from the stagedstr style if there are staged changes in the repository.
#   %u : The string from the unstagedstr style if there are unstaged changes in the repository.
#

# Set formats. (put the data into vcs_info_msg_*_ variables)
zstyle ':vcs_info:*' formats '(%s)-[%b]'
zstyle ':vcs_info:*' actionformats '(%s)-[%b|%a]'
zstyle ':vcs_info:(svn|bzr):*' branchformat '%b:%r'

autoload -Uz is-at-least
if is-at-least 4.3.10; then
    # In the case of zsh version >= 4.3.10
    zstyle ':vcs_info:git:*' check-for-changes true
    zstyle ':vcs_info:git:*' formats '%s' '%b'
    zstyle ':vcs_info:git:*' actionformats '%s' '%b' '%a'
fi


function vcs_super_info() {
    # Use python
    if [ "$ZSH_VCS_PROMPT_USING_PYTHON" = 'true' ] \
        && type python > /dev/null 2>&1 \
        && type git > /dev/null 2>&1 \
        && [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = "true" ]; then
        local git_status="$(_git_status_using_python)"
        if [ -n "$git_status" ]; then
            echo "(${VCS_NAME_COLOR_USING_PYTHON}git%{${reset_color}%})-[${git_status}]"
            return 0
        fi
    fi

    # Don't use python.
    psvar=()
    LANG=en_US.UTF-8 vcs_info

    if [ "${vcs_info_msg_0_}" = 'git' ]; then
        echo "(${VCS_NAME_COLOR}${vcs_info_msg_0_}%{${reset_color}%})-[$(_git_status)]%{${reset_color}%}"
    else
        echo "${VCS_NAME_COLOR}${vcs_info_msg_0_}%{${reset_color}%}"
    fi
    return 0
}


function _git_status() {
    local branch="${VCS_BRANCH_COLOR}${vcs_info_msg_1_}%{${reset_color}%}"
    if [ -n "$vcs_info_msg_2_" ]; then
        branch="$branch${VCS_ACTION_SEPARATOR}${VCS_ACTION_COLOR}${vcs_info_msg_2_}%{${reset_color}%}"
    fi
    local staged="${VCS_STAGED_COLOR}${VCS_STAGED_SIGIL}"
    local unstaged="${VCS_UNSTAGED_COLOR}${VCS_UNSTAGED_SIGIL}"
    local untracked="${VCS_UNTRACKED_COLOR}${VCS_UNTRACKED_SIGIL}"
    local stashed="${VCS_STASHED_COLOR}${VCS_STASHED_SIGIL}"
    local conflicts="${VCS_CONFLICTS_COLOR}${VCS_CONFLICTS_SIGIL}"
    local ahead="${VCS_REMOTE_COLOR}${VCS_AHEAD_SIGIL}"
    local behind="${VCS_REMOTE_COLOR}${VCS_BEHIND_SIGIL}"
    local clean="${VCS_CLEAN_COLOR}${VCS_CLEAN_SIGIL}%{${reset_color}%}"

    local conflicts_count=0

    local is_inside_work_tree=false
    if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = "true" ]; then
        is_inside_work_tree=true
    fi

    # staged
    local staged_files
    if [ "$is_inside_work_tree" = "true" ]; then
        staged_files="$(git diff --staged --name-status)"
    fi
    if [ -n "$staged_files" ];then
        conflicts_count=$(echo "$staged_files" | sed '/^[^U]/d' | wc -l | sed 's/ //g')

        staged_count=$(echo "$staged_files" | wc -l | sed 's/ //g')
        staged_count=$(($staged_count - $conflicts_count))

        if [ "$staged_count" -gt 0 ]; then
            staged="$staged$staged_count%{${reset_color}%}"
        else
            staged=''
        fi
    else
        staged=''
    fi

    # conflicts
    if [ "$conflicts_count" -gt 0 ]; then
        conflicts="$conflicts$conflicts_count%{${reset_color}%}"
    else
        conflicts=''
    fi

    # unstaged
    local unstaged_files
    if [ "$is_inside_work_tree" = "true" ]; then
        unstaged_files="$(git diff --name-status)"
    fi
    if [ -n "$unstaged_files" ]; then
        unstaged_count=$(echo "$unstaged_files" | sed '/^U/d' | wc -l | sed 's/ //g')
        unstaged="$unstaged$unstaged_count%{${reset_color}%}"
    else
        unstaged=''
    fi

    # untracked
    local untracked_files
    if [ "$is_inside_work_tree" = "true" ]; then
        untracked_files=$(git ls-files --others --exclude-standard)
    fi
    if [ -n "$untracked_files" ]; then
        untracked_count=$(echo "$untracked_files" | wc -l | sed 's/ //g')
        untracked="$untracked$untracked_count%{${reset_color}%}"
    else
        untracked=''
    fi

    # not pushed
    local tracking_branch=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))
    if [ -n "$tracking_branch" ]; then
        local -a behind_ahead
        behind_ahead=($(git rev-list --left-right --count $tracking_branch...HEAD))
        local behind_count=${behind_ahead[1]}
        local ahead_count=${behind_ahead[2]}

        if [[ $behind_count -gt 0 ]]; then
            behind="$behind$behind_count%{${reset_color}%}"
        else
            behind=''
        fi
        if [[ $ahead_count -gt 0 ]]; then
            ahead="$ahead$ahead_count%{${reset_color}%}"
        else
            ahead=''
        fi
    else
        behind=''
        ahead=''
    fi

    # stash
    local stash_list
    if [ "$is_inside_work_tree" = 'true' ]; then
        stash_list="$(git stash list)"
    fi
    if [ -n "$stash_list" ]; then
        stashed_count=$(echo "$stash_list" | wc -l | sed 's/ //g')
        stashed="$stashed$stashed_count%{${reset_color}%}"
    else
        stashed=''
    fi

    # result
    local git_status="${branch}${ahead}${behind}|${staged}${unstaged}${untracked}${conflicts}${stashed}"

    if [ "$is_inside_work_tree" = 'true' ]; then
        if [ -z "$staged" -a -z "$unstaged" -a -z "$untracked" -a -z "$conflicts" ]; then
            git_status="${git_status}${clean}"
        fi
    fi

    echo "$git_status%{${reset_color}%}"
}

function _git_status_using_python() {
    local cmd_gitstatus="${ZSH_VCS_PROMPT_DIR}/gitstatus-fast.py"

    if [ ! -f "$cmd_gitstatus" ]; then
        echo '[ zsh-vcs-prompt error: gitstatus-fast.py is not found ]'
        return 0
    fi

    local GIT_STATUS
    GIT_STATUS=$(python "$cmd_gitstatus" 2>/dev/null)
    if [ -z "$GIT_STATUS" ];then
        return 0
    fi

    local -a CURRENT_GIT_STATUS
    CURRENT_GIT_STATUS=("${(@f)GIT_STATUS}")
    local GIT_BRANCH=${CURRENT_GIT_STATUS[1]}
    local GIT_AHEAD=${CURRENT_GIT_STATUS[2]}
    local GIT_BEHIND=${CURRENT_GIT_STATUS[3]}
    local GIT_STAGED=${CURRENT_GIT_STATUS[4]}
    local GIT_CONFLICTS=${CURRENT_GIT_STATUS[5]}
    local GIT_UNSTAGED=${CURRENT_GIT_STATUS[6]}
    local GIT_UNTRACKED=${CURRENT_GIT_STATUS[7]}
    local GIT_STASHED=${CURRENT_GIT_STATUS[8]}
    local GIT_CLEAN=${CURRENT_GIT_STATUS[9]}


    local STATUS="($GIT_BRANCH"
    STATUS="$VCS_BRANCH_COLOR$GIT_BRANCH%{${reset_color}%}"
    if [ "$GIT_AHEAD" -ne 0 ]; then
        STATUS="$STATUS$VCS_REMOTE_COLOR$VCS_AHEAD_SIGIL$GIT_AHEAD%{${reset_color}%}"
    fi
    if [ "$GIT_BEHIND" -ne 0 ]; then
        STATUS="$STATUS$VCS_REMOTE_COLOR$VCS_BEHIND_SIGIL$GIT_BEHIND%{${reset_color}%}"
    fi
    STATUS="$STATUS|"
    if [ "$GIT_STAGED" -ne 0 ]; then
        STATUS="$STATUS$VCS_STAGED_COLOR$VCS_STAGED_SIGIL$GIT_STAGED%{${reset_color}%}"
    fi
    if [ "$GIT_CONFLICTS" -ne 0 ]; then
        STATUS="$STATUS$VCS_CONFLICTS_COLOR$VCS_CONFLICTS_SIGIL$GIT_CONFLICTS%{${reset_color}%}"
    fi
    if [ "$GIT_UNSTAGED" -ne 0 ]; then
        STATUS="$STATUS$VCS_UNSTAGED_COLOR$VCS_UNSTAGED_SIGIL$GIT_UNSTAGED%{${reset_color}%}"
    fi
    if [ "$GIT_UNTRACKED" -ne 0 ]; then
        STATUS="$STATUS$VCS_UNTRACKED_COLOR$VCS_UNTRACKED_SIGIL$GIT_UNTRACKED%{${reset_color}%}"
    fi
    if [ "$GIT_STASHED" -ne 0 ]; then
        STATUS="$STATUS$VCS_STASHED_COLOR$VCS_STASHED_SIGIL$GIT_STASHED%{${reset_color}%}"
    fi
    if [ "$GIT_CLEAN" -eq 1 ]; then
        STATUS="$STATUS$VCS_CLEAN_COLOR$VCS_CLEAN_SIGIL%{${reset_color}%}"
    fi
    STATUS="$STATUS%{${reset_color}%}"
    echo "$STATUS"
}

# vim: ft=zsh
