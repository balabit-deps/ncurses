/****************************************************************************
 * Copyright (c) 1998-2006,2008 Free Software Foundation, Inc.              *
 *                                                                          *
 * Permission is hereby granted, free of charge, to any person obtaining a  *
 * copy of this software and associated documentation files (the            *
 * "Software"), to deal in the Software without restriction, including      *
 * without limitation the rights to use, copy, modify, merge, publish,      *
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
 *     and: Juergen Pfeifer                         1996-on                 *
 *     and: Thomas E. Dickey                                                *
 ****************************************************************************/

/*
 *	lib_slkrefr.c
 *	Write SLK window to the (virtual) screen.
 */
#include <curses.priv.h>

MODULE_ID("$Id: lib_slkrefr.c,v 1.17.1.3 2009/02/07 23:09:40 tom Exp $")

/*
 * Paint the info line for the PC style SLK emulation.
 */
static void
slk_paint_info(WINDOW *win)
{
    SCREEN *sp = _nc_screen_of(win);

    if (win && sp && (sp->slk_format == 4)) {
	int i;

	mvwhline(win, 0, 0, 0, getmaxx(win));
	wmove(win, 0, 0);

	for (i = 0; i < sp->_slk->maxlab; i++) {
	    mvwprintw(win, 0, sp->_slk->ent[i].ent_x, "F%d", i + 1);
	}
    }
}

/*
 * Write the soft labels to the soft-key window.
 */
static void
slk_intern_refresh(SCREEN *sp)
{
    int i;
    int fmt;
    SLK *slk;
    int numlab;

    if (sp == 0)
	return;

    slk = sp->_slk;
    fmt = sp->slk_format;
    numlab = InfoOf(sp).numlabels;

    if (slk->hidden)
	return;

    for (i = 0; i < slk->labcnt; i++) {
	if (slk->dirty || slk->ent[i].dirty) {
	    if (slk->ent[i].visible) {
		if (numlab > 0 && SLK_STDFMT(fmt)) {
		    CallDriver_2(sp, hwlabel, i + 1, slk->ent[i].form_text);
		} else {
		    if (fmt == 4)
			slk_paint_info(slk->win);
		    wmove(slk->win, SLK_LINES(fmt) - 1, slk->ent[i].ent_x);
		    if (sp->_slk) {
			wattrset(slk->win, AttrOf(sp->_slk->attr));
		    }
		    waddstr(slk->win, slk->ent[i].form_text);
		    /* if we simulate SLK's, it's looking much more
		       natural to use the current ATTRIBUTE also
		       for the label window */
		    wattrset(slk->win, WINDOW_ATTRS(sp->_stdscr));
		}
	    }
	    slk->ent[i].dirty = FALSE;
	}
    }
    slk->dirty = FALSE;

    if (numlab > 0) {
	CallDriver_1(sp, hwlabelOnOff, slk->hidden ? FALSE : TRUE);
    }
}

/*
 * Refresh the soft labels.
 */
NCURSES_EXPORT(int)
NC_SNAME(slk_noutrefresh) (SCREEN *sp)
{
    T((T_CALLED("slk_noutrefresh(%p)"), sp));

    if (sp == 0 || sp->_slk == 0)
	returnCode(ERR);
    if (sp->_slk->hidden)
	returnCode(OK);
    slk_intern_refresh(sp);

    returnCode(wnoutrefresh(sp->_slk->win));
}

NCURSES_EXPORT(int)
slk_noutrefresh(void)
{
    return NC_SNAME(slk_noutrefresh) (CURRENT_SCREEN);
}

/*
 * Refresh the soft labels.
 */
NCURSES_EXPORT(int)
NC_SNAME(slk_refresh) (SCREEN *sp)
{
    T((T_CALLED("slk_refresh(%p)"), sp));

    if (sp == 0 || sp->_slk == 0)
	returnCode(ERR);
    if (sp->_slk->hidden)
	returnCode(OK);
    slk_intern_refresh(sp);

    returnCode(wrefresh(sp->_slk->win));
}

NCURSES_EXPORT(int)
slk_refresh(void)
{
    return NC_SNAME(slk_refresh) (CURRENT_SCREEN);
}
