" Documentation {{{1
"
" Name: webBrowser.vim
" Version: 1.4
" Description: Uses the lynx text browser to browse websites and local files and return the rendered web pages inside vim. The links in the web pages may be "clicked" to follow them, so it turns vim into a simple web text based web browser. This plugin is based on the "browser.vim" plugin.
" Author: Alexandre Viau (alexandreviau@gmail.com)
" Website: The latest version is found on "vim.org"
"
" Installation: {{{2 
" Copy the plugin to the vim plugin directory.
" In the lynx.cfg file, set the following parameters: 
" ACCEPT_ALL_COOKIES:TRUE
" MAKE_LINKS_FOR_ALL_IMAGES:TRUE

" Todo: {{{2
" - To abandon this plugin (learn better vimperator or pentadactyl), or to redo it especially the code that gets the link number and search for it at the end of the file (no need to move cursor) and to do it in a mapping, it may be done in a function
" - I added basicXmlParser in the plugin, add a webBrowser.xml file and in it, have 2 keys: history and favorites, which will be string of utl links
" - Add links bar like vimExplorer (favorites & history) with links not from utl but with brackets [http://yahoo.com] thus no need for utl
" - Use image_links and accept_all_cookies options in the command run from the plugin instead of having to modify the .cfg file
"
" Tests: {{{2 
" Links to use for testing the plugin with the utl plugin
" <url:http://www.cars.com/crp/vp/images/13ford_fusion/Titanium_Action_7.jpg>
" <url:http://www.bobpiper.co.uk/My%20favourite%20Tree.jpg> 
" <url:http://www.codeproject.com/Articles/36091/Top-10-steps-to-optimize-data-access-in-SQL-Server> 
" <url:http://www.cheat-sheets.org/>
" <url:http://www.cheat-sheets.org/saved-copy/msnet-formatting-strings.pdf>
" <url:http://www.cars.com>
" <url:http://www.smartisans.com/articles/vb_templates.aspx>
" 
" History {{{2
" 1.1 {{{3
" - Changed the file format to unix
" 1.2 {{{3
" - Changed the mappings
" 1.3 {{{3
" - Now the lynx command and others are ran using a call to the system() function so that the dos prompt window is not displayed on the screen
" - Added suggested mappings in comments (<insert>, <delete>, etc)
" - Added folds
" 1.4 {{{3
" - Changed mappings \wb etc to <leader>wb because it was causing my "w" key in normal mode to wait for another key

" Commands: To start the plugin {{{1
com! -nargs=+ WebBrowser call OpenWebBrowser(<q-args>, 1)

" Mappings: To start the plugin {{{1
" Open a new web browser tab with the address specified
nmap <leader>wb :WebBrowser 
" Open a new web browser tab with the address in the clipboard 
nmap <leader>wc :exe 'WebBrowser "' . @* . '"'<cr>
" Do a google search using the specified search keywords and open the results in a new tab
nmap <leader>wg :exe 'WebBrowser www.google.com/search?q="' . input("Google ") . '"'<cr>
" Do a wikipedia search using the specified search keywords and open the results in a new tab
nmap <leader>wp :exe 'WebBrowser www.wikipedia.com/wiki/"' . input("Wikipedia ") . '"'<cr>

" Suggested mappings to add to your vimrc {{{2
" Open a web browser tab with the address specified
" nmap <insert> :WebBrowser 
" Open a new web browser tab with the address in the clipboard 
" nmap <s-insert> :exe 'WebBrowser ' . @*<cr>
" Show dump (history-cache) directory
" nmap <c-insert> :exe 'VimExplorerSP ' . g:WbLynxDumpPath<cr>
" Do a google search using the specified search keywords and open the results in a new tab
" nmap <delete> :exe 'WebBrowser www.google.com/search?q="' . input("Google ") . '"'<cr>
" Do a wikipedia search using the specified search keywords and open the results in a new tab
" nmap <s-delete> :exe 'WebBrowser www.wikipedia.com/wiki/"' . input("Wikipedia ") . '"'<cr>

" Variables {{{1
let s:lynxPath = 'c:\lynx\'
let s:lynxExe = s:lynxPath . 'lynx.exe'
let s:lynxCfg = '-cfg=' . s:lynxPath . 'lynx.cfg'
let s:lynxLss = '-lss=' . s:lynxPath . 'lynx.lss'
let s:lynxCmd = s:lynxExe . ' ' . s:lynxCfg . ' ' . s:lynxLss

let g:WbLynxDumpPath = 'c:\lynx\dump\'
let s:lynxToolsPath = 'c:\lynx\tools\'

let g:WbAddress = ''

" Initialization {{{1
" Create path to dump the files (may act as an history path but files of same name are replaced) {{{2
if isdirectory(g:WbLynxDumpPath) == 0
    call mkdir(g:WbLynxDumpPath)
endif

" Functions {{{1
function! OpenWebBrowser(address, openInNewTab) " {{{2
    " Percent-encode some characters because it causes problems in the command line on the windows test computer {{{3
    "! 	# 	$ 	& 	' 	( 	) 	* 	+ 	, 	/ 	: 	; 	= 	? 	@ 	[ 	]
    "%21 	%23 	%24 	%26 	%27 	%28 	%29 	%2A 	%2B 	%2C 	%2F 	%3A 	%3B 	%3D 	%3F 	%40 	%5B 	%5D
    let l:address = substitute(a:address, '&', '\\%26', 'g')
    let l:address = substitute(l:address, '#', '\\%23', 'g')
    " Substitute invalid characters
    let l:dumpFile = substitute(l:address, '\', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '/', '-', 'g')
    let l:dumpFile = substitute(l:dumpFile, ':', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '*', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '?', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '"', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '<', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '>', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '|', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '%', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '=', '_', 'g')
    " Get extension of the file {{{3
    let l:extPos = strridx(a:address, '.')
    let l:extLen = strlen(a:address) - l:extPos
    let l:extName = strpart(a:address, l:extPos, l:extLen)
    " Open the webpage/file and dump it using the lynx -dump feature to the dump directory {{{3
    exe 'silent ! ' . s:lynxCmd . ' -dump ' . l:address . ' > "' . g:WbLynxDumpPath . l:dumpFile . '"'
    " Select view method according to the page/file extension {{{3
    let l:vimFile = ''
    " View image files {{{4
    if l:extName == '.jpg' || l:extName == '.gif' || l:extName == '.png'
        " Windows
        if has('Win32')
            exe 'silent !start "' . s:lynxToolsPath . 'i_view32.exe" "' . g:WbLynxDumpPath . l:dumpFile . '"'
        " Linux
        else
            exe 'silent !"' . s:lynxToolsPath . 'i_view32.exe" "' . g:WbLynxDumpPath . l:dumpFile . '"'
        endif
    " View pdf files {{{4
    elseif l:extName == '.pdf'
        exe 'silent ! "' . s:lynxToolsPath . 'pdftotext.exe" "' . g:WbLynxDumpPath . l:dumpFile . '" "' . g:WbLynxDumpPath . l:dumpFile . '.txt"'
        let l:vimFile = g:WbLynxDumpPath . l:dumpFile . '.txt'
    " View any other extension (html, htm or no extension etc.) {{{4
    else
        let l:vimFile = g:WbLynxDumpPath . l:dumpFile
    endif
    " Open the dumped file in the buffer {{{3
    if l:vimFile != ''
        if a:openInNewTab == 1
            exe "tabnew"
            exe "set buftype=nofile"
            " Open link
            exe 'nnoremap <buffer> <space>l F[h/^ *<c-r><c-w>. \(http\\|file\)<cr>f l"py$:call OpenWebBrowser("<c-r>p", 0)<cr>'
            " Previous page ("back button")
            exe 'nnoremap <buffer> <space>h :normal u<cr>'
            " Highlight links and go to next link
            exe "nnoremap <buffer> <space>j /\\d*\\]\\w*<cr>"
            " Highlight links and go to previous link
            exe "nnoremap <buffer> <space>k ?\\d*\\]\\w*<cr>"
        else
            " Clear the buffer
            exe "norm ggdG"
        endif
        " Read the file in the buffer
        exe 'silent r ' . l:vimFile
        " Set syntax to have bold links
        syn reset
        syn match Keyword /\[\d*\]\w*/ contains=Ignore
        syn match Ignore /\[\d*\]/ contained 
        exe "norm gg"
        let g:WbAddress = substitute(a:address, '"', '', 'g') 
        call append(0, [g:WbAddress])
        exe "norm k"
    else
        " Return to previous cursor position to return to where the link was executed
        exe "norm! \<c-o>"
    endif 
    " Add address to append register which acts as an history for the current session
    "let @H = strftime("%x %X") . ' <url:' . g:WbAddress . '>
'
endfun
