/****************************************************************************
 * Copyright (c) 1998-2007,2008 Free Software Foundation, Inc.              *
 *                                                                          *
 * Permission is hereby granted, free of charge, to any person obtaining a  *
 * copy of this software and associated documentation files (the            *
 * "Software"), to deal in the Software without restriction, including      *
 * without limitation the rights to use, copy, getmodify, merge, publish,      *
 * distribute, distribute with modifications, sublicense, and/or sell       *
 * copies of the Software, and to permit persons to whom the Software is    *
 * furnished to do so, subject to the following conditions:                 *
 *                                                                          *
 * The above copyright notice and this permission notice shall be included  *
 * in all copies or substantial portions of the Software.                   *
 *                                                                          *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS  *
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF               *
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.   *
 * IN NO EVENT SHALL THE ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,   *
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR    *
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR    *
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.                               *
 *                                                                          *
 * Except as contained in this notice, the name(s) of the above copyright   *
 * holders shall not be used in advertising or otherwise to promote the     *
 * sale, use or other dealings in this Software without prior written       *
 * authorization.                                                           *
 ****************************************************************************/

/****************************************************************************
 *  Author: Zeyd M. Ben-Halim <zmbenhal@netcom.com> 1992,1995               *
 *     and: Eric S. Raymond <esr@snark.thyrsus.com>                         *
 *     and: Thomas E. Dickey                        1996-on                 *
 ****************************************************************************/

/*
 * Terminal setup routines common to termcap and terminfo:
 *
 *		use_env(bool)
 *		setupterm(char *, int, int *)
 */

#include <curses.priv.h>
#include <tic.h>		/* for MAX_NAME_SIZE */
#include <term_entry.h>

#if SVR4_TERMIO && !defined(_POSIX_SOURCE)
#define _POSIX_SOURCE
#endif

#if HAVE_LOCALE_H
#include <locale.h>
#endif

MODULE_ID("$Id: lib_setup.c,v 1.111.1.1 2008/11/16 00:19:59 juergen Exp $")

/****************************************************************************
 *
 * Terminal size computation
 *
 ****************************************************************************/

#if HAVE_SIZECHANGE
# if !defined(sun) || !TERMIOS
#  if HAVE_SYS_IOCTL_H
#   include <sys/ioctl.h>
#  endif
# endif
#endif

#if NEED_PTEM_H
 /* On SCO, they neglected to define struct winsize in termios.h -- it's only
  * in termio.h and ptem.h (the former conflicts with other definitions).
  */
# include <sys/stream.h>
# include <sys/ptem.h>
#endif

#if HAVE_LANGINFO_CODESET
#include <langinfo.h>
#endif

/*
 * Reduce explicit use of "cur_term" global variable.
 */
#undef CUR
#define CUR termp->type.


/*
 * Wrap global variables in this module.
 */
#if USE_REENTRANT

NCURSES_EXPORT(char *)
NC_SNAME(_nc_ttytype)(SCREEN *sp)
{
    static char empty[] = "";
    if (sp) {
	TERMINAL *termp = TerminalOf(sp);
	return (termp ? termp->type.term_names : empty);
    } else
	return empty;
}

NCURSES_EXPORT(char *)
NCURSES_PUBLIC_VAR(ttytype) (void)
{
    return NC_SNAME(_nc_ttytype)(CURRENT_SCREEN);
}

NCURSES_EXPORT(int *)
_nc_ptr_Lines(SCREEN *sp)
{
    return ptrLines(sp);
}

NCURSES_EXPORT(int)
NCURSES_PUBLIC_VAR(LINES) (void)
{
    return *(_nc_ptr_Lines(CURRENT_SCREEN));
}

NCURSES_EXPORT(int *)
_nc_ptr_Cols(SCREEN *sp)
{
    return ptrCols(sp);
}

NCURSES_EXPORT(int)
NCURSES_PUBLIC_VAR(COLS) (void)
{
    return *(_nc_ptr_Cols(CURRENT_SCREEN));
}

NCURSES_EXPORT(int *)
_nc_ptr_Tabsize(SCREEN *sp)
{
    if (sp)
	return &(sp->_TABSIZE);
    else
	return  (&_nc_prescreen._TABSIZE);
}

NCURSES_EXPORT(int)
NCURSES_PUBLIC_VAR(TABSIZE) (void)
{
    return *(_nc_ptr_Tabsize(CURRENT_SCREEN));
}
#else
NCURSES_EXPORT_VAR(char) ttytype[NAMESIZE] = "";
NCURSES_EXPORT_VAR(int) LINES = 0;
NCURSES_EXPORT_VAR(int) COLS = 0;
NCURSES_EXPORT_VAR(int) TABSIZE = 8;

NCURSES_EXPORT(int *)
_nc_ptr_Tabsize(SCREEN *sp GCC_UNUSED)
{
    return &TABSIZE;
}

NCURSES_EXPORT(int *)
_nc_ptr_Lines(SCREEN *sp GCC_UNUSED)
{
    return &LINES;
}

NCURSES_EXPORT(int *)
_nc_ptr_Cols(SCREEN *sp GCC_UNUSED)
{
    return &COLS;
}
#endif

#if NCURSES_EXT_FUNCS
NCURSES_EXPORT(int)
NC_SNAME(set_tabsize)(
			  SCREEN *sp
#if !USE_REENTRANT
			  GCC_UNUSED
#endif
			  , int value)
{
    int code = OK;
#if USE_REENTRANT
    if (sp) {
	sp->_TABSIZE = value;
    } else {
	code = ERR;
    }
#else
    TABSIZE = value;
#endif
    return code;
}

NCURSES_EXPORT(int)
set_tabsize (int value)
{
    return NC_SNAME(set_tabsize)(CURRENT_SCREEN, value);
}
#endif

#if USE_SIGWINCH
/*
 * If we have a pending SIGWINCH, set the flag in each screen.
 */
NCURSES_EXPORT(int)
_nc_handle_sigwinch(SCREEN *sp)
{
    SCREEN *scan;

    if (_nc_globals.have_sigwinch) {
	_nc_globals.have_sigwinch = 0;

	for (each_screen(scan)) {
	    scan->_sig_winch = TRUE;
	}
    }

    return (sp ? sp->_sig_winch : 0);
}

#endif

NCURSES_EXPORT(void)
use_env(bool f)
{
    T((T_CALLED("use_env()")));
    _nc_prescreen.use_env = f;
    returnVoid;
}

NCURSES_EXPORT(void)
_nc_get_screensize(SCREEN* sp
#if !USE_REENTRANT
		   GCC_UNUSED
#endif
		   , TERMINAL* termp, int *linep, int *colp)
/* Obtain lines/columns values from the environment and/or terminfo entry */
{
    TERMINAL_CONTROL_BLOCK* TCB;
    int my_tabsize;
  
    assert(termp!=0 && linep!=0 && colp!=0);
    TCB = (TERMINAL_CONTROL_BLOCK*)termp;

    my_tabsize = TCB->info->tabsize;
    TCB->drv->size(TCB,linep,colp);

#if USE_REENTRANT
    if (sp != 0) {
	sp->_TABSIZE = my_tabsize;
    }
#else
    TABSIZE = my_tabsize;
#endif
    T(("TABSIZE = %d", my_tabsize));
}

#if USE_SIZECHANGE
NCURSES_EXPORT(void)
_nc_update_screensize(SCREEN *sp)
{
    int old_lines;
    int new_lines;
    int old_cols;
    int new_cols;

    assert(sp!=0);

    CallDriver_2(sp,getsize,&old_lines,&old_cols);
    _nc_get_screensize(sp, sp->_term, &new_lines, &new_cols);

    /*
     * See is_term_resized() and resizeterm().
     * We're doing it this way because those functions belong to the upper
     * ncurses library, while this resides in the lower terminfo library.
     */
    if (sp != 0
	&& sp->_resize != 0) {
	if ((new_lines != old_lines) || (new_cols != old_cols))
	    sp->_resize(sp, new_lines, new_cols);
	sp->_sig_winch = FALSE;
    }
}
#endif

/****************************************************************************
 *
 * Terminal setup
 *
 ****************************************************************************/

#define ret_error(code, fmt, arg)	if (errret) {\
					    *errret = code;\
					    returnCode(ERR);\
					} else {\
					    fprintf(stderr, fmt, arg);\
					    exit(EXIT_FAILURE);\
					}

#define ret_error0(code, msg)		if (errret) {\
					    *errret = code;\
					    returnCode(ERR);\
					} else {\
					    fprintf(stderr, msg);\
					    exit(EXIT_FAILURE);\
					}


/*
 * Find the locale which is in effect.
 */
NCURSES_EXPORT(char *)
_nc_get_locale(void)
{
    char *env;
#if HAVE_LOCALE_H
    /*
     * This is preferable to using getenv() since it ensures that we are using
     * the locale which was actually initialized by the application.
     */
    env = setlocale(LC_CTYPE, 0);
#else
    if (((env = getenv("LC_ALL")) != 0 && *env != '\0')
	|| ((env = getenv("LC_CTYPE")) != 0 && *env != '\0')
	|| ((env = getenv("LANG")) != 0 && *env != '\0')) {
	;
    }
#endif
    T(("_nc_get_locale %s", _nc_visbuf(env)));
    return env;
}

/*
 * Check if we are running in a UTF-8 locale.
 */
NCURSES_EXPORT(int)
_nc_unicode_locale(void)
{
    int result = 0;
#if HAVE_LANGINFO_CODESET
    char *env = nl_langinfo(CODESET);
    result = !strcmp(env, "UTF-8");
    T(("_nc_unicode_locale(%s) ->%d", env, result));
#else
    char *env = _nc_get_locale();
    if (env != 0) {
	if (strstr(env, ".UTF-8") != 0) {
	    result = 1;
	    T(("_nc_unicode_locale(%s) ->%d", env, result));
	}
    }
#endif
    return result;
}

#define CONTROL_N(s) ((s) != 0 && strstr(s, "\016") != 0)
#define CONTROL_O(s) ((s) != 0 && strstr(s, "\017") != 0)

/*
 * Check for known broken cases where a UTF-8 locale breaks the alternate
 * character set.
 */
NCURSES_EXPORT(int)
_nc_locale_breaks_acs(TERMINAL * termp)
{
    char *env;

    if ((env = getenv("NCURSES_NO_UTF8_ACS")) != 0) {
	return atoi(env);
    } else if ((env = getenv("TERM")) != 0) {
	if (strstr(env, "linux"))
	    return 1;		/* always broken */
	if (strstr(env, "screen") != 0
	    && ((env = getenv("TERMCAP")) != 0
		&& strstr(env, "screen") != 0)
	    && strstr(env, "hhII00") != 0) {
	    if (CONTROL_N(enter_alt_charset_mode) ||
		CONTROL_O(enter_alt_charset_mode) ||
		CONTROL_N(set_attributes) ||
		CONTROL_O(set_attributes))
		return 1;
	}
    }
    return 0;
}

NCURSES_EXPORT(int)
_nc_setupterm_ex(TERMINAL ** tp,
		 NCURSES_CONST char *tname,
		 int Filedes,
		 int *errret,
		 bool reuse)
{
    TERMINAL *termp;
    TERMINAL_CONTROL_BLOCK* TCB = 0;
    SCREEN* sp = 0;
    int code = ERR;
    
    START_TRACE();
    T((T_CALLED("_nc_setupterm_ex(%p,%s,%d,%p)"),
       tp, _nc_visbuf(tname), Filedes, errret));

    if (tp == 0) {
	ret_error0(TGETENT_ERR,
		   "Invalid paramter, internal error.\n");
    } else
	termp = *tp;

    if (tname == 0) {
	tname = getenv("TERM");
	if (tname == 0 || *tname == '\0') {
	    ret_error0(TGETENT_ERR, "TERM environment variable not set.\n");
	}
    }

    if (strlen(tname) > MAX_NAME_SIZE) {
	ret_error(TGETENT_ERR,
		  "TERM environment must be <= %d characters.\n",
		  MAX_NAME_SIZE);
    }

    T(("your terminal name is %s", tname));

    /*
     * Allow output redirection.  This is what SVr3 does.  If stdout is
     * directed to a file, screen updates go to standard error.
     */
    if (Filedes == STDOUT_FILENO && !isatty(Filedes))
	Filedes = STDERR_FILENO;

    /*
     * Check if we have already initialized to use this terminal.  If so, we
     * do not need to re-read the terminfo entry, or obtain TTY settings.
     *
     * This is an improvement on SVr4 curses.  If an application mixes curses
     * and termcap calls, it may call both initscr and tgetent.  This is not
     * really a good thing to do, but can happen if someone tries using ncurses
     * with the readline library.  The problem we are fixing is that when
     * tgetent calls setupterm, the resulting Ottyb struct in cur_term is
     * zeroed.  A subsequent call to endwin uses the zeroed terminal settings
     * rather than the ones saved in initscr.  So we check if cur_term appears
     * to contain terminal settings for the same output file as our current
     * call - and copy those terminal settings.  (SVr4 curses does not do this,
     * however applications that are working around the problem will still work
     * properly with this feature).
     */
    if (reuse
	&& (termp != 0)
	&& termp->Filedes == Filedes
	&& termp->_termname != 0
	&& !strcmp(termp->_termname, tname)
	&& _nc_name_match(termp->type.term_names, tname, "|")
	) {
	  T(("reusing existing terminal information and mode-settings"));
	  code = OK;
    } else {
        termp = (TERMINAL*)typeCalloc(TERMINAL_CONTROL_BLOCK,1);
	if (termp == 0) {
	    ret_error0(TGETENT_ERR,
		       "Not enough memory to create terminal structure.\n");
	}
	TCB = (TERMINAL_CONTROL_BLOCK*)termp;
	code = _nc_get_driver(TCB,tname,errret);
	if (code==OK)
	{
	  termp->Filedes = Filedes;
	  termp->_termname = strdup(tname);	  
	}
	else
	{
	  ret_error0(TGETENT_ERR,
		     "Could not find any driver to handle this terminal.\n");
	}
    }
    
    *tp = termp;
    NC_SNAME(_nc_set_curterm)(sp,termp);
    TCB->drv->init(TCB);

    /*
     * We should always check the screensize, just in case.
     */
    _nc_get_screensize(sp, termp, ptrLines(sp), ptrCols(sp));

    if (errret)
	*errret = TGETENT_YES;

    returnCode(code);
}

/*
 * This entrypoint is called from tgetent() to allow a special case of reusing
 * the same TERMINAL data (see comment).
 */
NCURSES_EXPORT(int)
_nc_setupterm (NCURSES_CONST char *tname,
	       int Filedes,
	       int *errret,
	       bool reuse)
{
    TERMINAL *termp;
    int res = _nc_setupterm_ex(&termp, tname, Filedes, errret, reuse);
    if (ERR != res)
        NC_SNAME(_nc_set_curterm)(CURRENT_SCREEN_PRE, termp);
    return res;
}

/*
 *	setupterm(termname, Filedes, errret)
 *
 *	Find and read the appropriate object file for the terminal
 *	Make cur_term point to the structure.
 */
NCURSES_EXPORT(int)
setupterm (NCURSES_CONST char *tname, int Filedes, int *errret)
{
    return _nc_setupterm (tname, Filedes, errret, FALSE);
}

