

/***************************************************************************
*                            COPYRIGHT NOTICE                              *
****************************************************************************
*                ncurses is copyright (C) 1992-1995                        *
*                          by Zeyd M. Ben-Halim                            *
*                          zmbenhal@netcom.com                             *
*                                                                          *
*        Permission is hereby granted to reproduce and distribute ncurses  *
*        by any means and for any fee, whether alone or as part of a       *
*        larger distribution, in source or in binary form, PROVIDED        *
*        this notice is included with any such distribution, not removed   *
*        from header files, and is reproduced in any documentation         *
*        accompanying it or the applications linked with it.               *
*                                                                          *
*        ncurses comes AS IS with no warranty, implied or expressed.       *
*                                                                          *
***************************************************************************/


/*
**	lib_longname.c
**
**	The routine longname().
**
*/

#include <string.h>
#include "curses.priv.h"

char *
longname()
{
char	*ptr;

	T(("longname() called"));

	for (ptr = ttytype + strlen(ttytype); ptr > ttytype; ptr--)
	   	if (*ptr == '|')
			return(ptr + 1);

    return(ttytype);
}
