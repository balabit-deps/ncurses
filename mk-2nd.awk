# $Id: mk-2nd.awk,v 1.8 1997/12/20 19:37:01 tom Exp $
################################################################################
# Copyright 1996,1997 by Thomas E. Dickey <dickey@clark.net>                   #
# All Rights Reserved.                                                         #
#                                                                              #
# Permission to use, copy, modify, and distribute this software and its        #
# documentation for any purpose and without fee is hereby granted, provided    #
# that the above copyright notice appear in all copies and that both that      #
# copyright notice and this permission notice appear in supporting             #
# documentation, and that the name of the above listed copyright holder(s) not #
# be used in advertising or publicity pertaining to distribution of the        #
# software without specific, written prior permission. THE ABOVE LISTED        #
# COPYRIGHT HOLDER(S) DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,    #
# INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT #
# SHALL THE ABOVE LISTED COPYRIGHT HOLDER(S) BE LIABLE FOR ANY SPECIAL,        #
# INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM   #
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE   #
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR    #
# PERFORMANCE OF THIS SOFTWARE.                                                #
################################################################################
# Generate compile-rules for the modules that we are using in libraries or
# programs.  We are listing them explicitly because we have turned off the
# suffix rules (to force compilation with the appropriate flags).  We could use
# make-recursion but that would result in makefiles that are useless for
# development.
#
# Variables:
#	model
#	MODEL (uppercase version of "model"; toupper is not portable)
#	echo (yes iff we will show the $(CC) lines)
#	subset ("none", "base", "base+ext_funcs" or "termlib")
#
# Fields in src/modules:
#	$1 = module name
#	$2 = progs|lib|c++
#	$3 = source-directory
#
# Fields in src/modules past $3 are dependencies
#
BEGIN	{
		found = 0
		using = 0
	}
	/^@/ {
		using = 0
		if (subset == "none") {
			using = 1
		} else if (index(subset,$2) > 0) {
			if (using == 0) {
				if (found == 0) {
					print  ""
					print  "# generated by mk-2nd.awk"
					print  ""
				}
				using = 1
			}
		}
	}
	!/^[@#]/ && !/^$/ {
		if (using != 0) {
			found = 1
			if ( $1 != "" ) {
				print  ""
				if ( $2 == "c++" ) {
					compile="CXX"
					suffix=".cc"
				} else {
					compile="CC"
					suffix=".c"
				}
				printf "../%s/%s.o :\t%s/%s%s", model, $1, $3, $1, suffix
				for (n = 4; n <= NF; n++) printf " \\\n\t\t\t%s", $n
				print  ""
				if ( echo == "yes" )
					atsign=""
				else {
					atsign="@"
					printf "\t@echo 'compiling %s (%s)'\n", $1, model
				}
				if ( $3 == "." || srcdir == "." )
					printf "\t%scd ../%s; $(%s) $(CFLAGS_%s) -c ../%s/%s%s", atsign, model, compile, MODEL, name, $1, suffix
				else
					printf "\t%scd ../%s; $(%s) $(CFLAGS_%s) -c %s/%s%s", atsign, model, compile, MODEL, $3, $1, suffix
			} else {
				printf "%s", $1
				for (n = 2; n <= NF; n++) printf " %s", $n
			}
			print  ""
		}
	}
END	{
		print  ""
	}
