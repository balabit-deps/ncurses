/*
 * $Id: firework.c,v 1.7 1996/11/17 00:17:32 tom Exp $
 */
#include <test.priv.h>

#include <term.h>	/* for tparm() */

#include <signal.h>
#include <ctype.h>
#include <time.h>

static char *normal, *hidden;

static int get_colour(void);
static void explode(int row, int col);
static void showit(void);
static void onsig(int sig);

int main(
	int argc GCC_UNUSED,
	char *argv[] GCC_UNUSED)
{
int j;
int start,end,row,diff,flag = 0,direction;
unsigned seed;

       for (j=SIGHUP;j<=SIGTERM;j++)
	   if (signal(j,SIG_IGN)!=SIG_IGN) signal(j,onsig);

       initscr();
       if (has_colors())
          start_color();
       if ((normal = tigetstr("cnorm")) != 0
        && (hidden = tigetstr("civis")) != 0)
    	   putp(tparm(hidden));

       seed = time((time_t *)0);
       srand(seed);
       cbreak();
       for (;;) {
            do {
                start = rand() % (COLS -3);
                end = rand() % (COLS - 3);
                start = (start < 2) ? 2 : start;
                end = (end < 2) ? 2 : end;
                direction = (start > end) ? -1 : 1;
                diff = abs(start-end);
            } while (diff<2 || diff>=LINES-2);
            attrset(A_NORMAL);
            for (row=0;row<diff;row++) {
                mvprintw(LINES - row,start + (row * direction),
                    (direction < 0) ? "\\" : "/");
                if (flag++) {
                    showit();
                    erase();
                    flag = 0;
                }
            }
            if (flag++) {
                showit();
                flag = 0;
            }
            seed = time((time_t *)0);
            srand(seed);
            explode(LINES-row,start+(diff*direction));
            erase();
            showit();
       }
}

static RETSIGTYPE
onsig(int n)
{
    putp(tparm(normal));
    endwin();
    exit(n);
}

static
void explode(int row, int col)
{
       erase();
       mvprintw(row,col,"-");
       showit();

       init_pair(1,get_colour(),COLOR_BLACK);
       attrset(COLOR_PAIR(1));
       mvprintw(row-1,col-1," - ");
       mvprintw(row,col-1,"-+-");
       mvprintw(row+1,col-1," - ");
       showit();

       init_pair(1,get_colour(),COLOR_BLACK);
       attrset(COLOR_PAIR(1));
       mvprintw(row-2,col-2," --- ");
       mvprintw(row-1,col-2,"-+++-");
       mvprintw(row,  col-2,"-+#+-");
       mvprintw(row+1,col-2,"-+++-");
       mvprintw(row+2,col-2," --- ");
       showit();

       init_pair(1,get_colour(),COLOR_BLACK);
       attrset(COLOR_PAIR(1));
       mvprintw(row-2,col-2," +++ ");
       mvprintw(row-1,col-2,"++#++");
       mvprintw(row,  col-2,"+# #+");
       mvprintw(row+1,col-2,"++#++");
       mvprintw(row+2,col-2," +++ ");
       showit();

       init_pair(1,get_colour(),COLOR_BLACK);
       attrset(COLOR_PAIR(1));
       mvprintw(row-2,col-2,"  #  ");
       mvprintw(row-1,col-2,"## ##");
       mvprintw(row,  col-2,"#   #");
       mvprintw(row+1,col-2,"## ##");
       mvprintw(row+2,col-2,"  #  ");
       showit();

       init_pair(1,get_colour(),COLOR_BLACK);
       attrset(COLOR_PAIR(1));
       mvprintw(row-2,col-2," # # ");
       mvprintw(row-1,col-2,"#   #");
       mvprintw(row,  col-2,"     ");
       mvprintw(row+1,col-2,"#   #");
       mvprintw(row+2,col-2," # # ");
       showit();
}

static
int get_colour(void)
{
 int attr;
       attr = (rand() % 16)+1;
       if (attr == 1 || attr == 9)
          attr = COLOR_RED;
       if (attr > 8)
          attr |= A_BOLD;
       return(attr);
}

static void
showit(void)
{
	refresh();
	napms(120);
}
