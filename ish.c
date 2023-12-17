#include <stdio.h>
#include <stdlib.h>

#include "lexsyn.h"
#include "util.h"

/*--------------------------------------------------------------------*/
/* ish.c                                                              */
/* Original Author: Bob Dondero                                       */
/* Modified by : Park Ilwoo                                           */
/* Illustrate lexical analysis using a deterministic finite state     */
/* automaton (DFA)                                                    */
/*--------------------------------------------------------------------*/

static void
shellHelper(const char *inLine) {
  DynArray_T oTokens;

  enum LexResult lexcheck;
  enum SyntaxResult syncheck;
  enum BuiltinType btype;

  oTokens = DynArray_new(0);
  if (oTokens == NULL) {
    errorPrint("Cannot allocate memory", FPRINTF);
    exit(EXIT_FAILURE);
  }


  lexcheck = lexLine(inLine, oTokens);
  
  switch (lexcheck) {
    case LEX_SUCCESS:
      if (DynArray_getLength(oTokens) == 0)
        return;

      /* dump lex result when DEBUG is set */
      dumpLex(oTokens);
      syncheck = syntaxCheck(oTokens);
      if (syncheck == SYN_SUCCESS) {
        btype = checkBuiltin(DynArray_get(oTokens, 0));
        if(btype == B_CD){
          struct Token* t = DynArray_get(oTokens, 1);
          chdir(t->pcValue);
          fprintf(stdout,"%% ");
          fflush(stdout);
          t->pcValue[strlen(t->pcValue) - 1] = '\n';
          fprintf(stdout,"%s\n",t->pcValue);
          fflush(stdout);

        }
        else if(btype == B_FG){

        }
        else if(btype == B_EXIT){
          exit(0);
        }
        else if(btype == B_SETENV){
          struct Token* varToken = DynArray_get(oTokens, 1);
                struct Token* valueToken = DynArray_get(oTokens, 2);
                if (varToken != NULL && valueToken != NULL) {
                  if (setenv(varToken->pcValue, valueToken->pcValue, 1) != 0) {
                    perror("setenv");
                  } else {
                    fprintf(stdout,"%% ");
                    fflush(stdout);
                  }
                } else {
                  fprintf(stderr, "setenv: missing variable or value\n");
                }
        }
        else if (btype == B_USETENV){
          struct Token* varToken = DynArray_get(oTokens, 1);
                if (varToken != NULL) {
                  if (unsetenv(varToken->pcValue) != 0) {
                    perror("unsetenv");
                  } else {
                    frintf("%% ");
                    fflush(stdout);
                  }
                } else {
                  fprintf(stderr, "unsetenv: missing variable\n");
                }
        }
        else if (btype == B_ALIAS){

        }
        else if (btype == NORMAL){
          struct Token* t = DynArray_get(oTokens, 0);
          if(strncmp(t->pcValue, "printenv", 8) == 0){
            struct Token* varToken = DynArray_get(oTokens, 1);
                if (varToken != NULL) {
                  char* envValue = getenv(varToken->pcValue);
                  if (envValue != NULL) {
                    fprintf(stdout,"%% ");
                    fflush(stdout);
                    fprintf(stdout, "%s\n", envValue);
                  } else {
                    fprintf(stderr, "printenv: variable not found\n");
                  }
                } else {
                  fprintf(stderr, "printenv: missing variable\n");
                }
          }
        }
      }

      /* syntax error cases */
      else if (syncheck == SYN_FAIL_NOCMD)
        errorPrint("Missing command name", FPRINTF);
      else if (syncheck == SYN_FAIL_MULTREDOUT)
        errorPrint("Multiple redirection of standard out", FPRINTF);
      else if (syncheck == SYN_FAIL_NODESTOUT)
        errorPrint("Standard output redirection without file name", FPRINTF);
      else if (syncheck == SYN_FAIL_MULTREDIN)
        errorPrint("Multiple redirection of standard input", FPRINTF);
      else if (syncheck == SYN_FAIL_NODESTIN)
        errorPrint("Standard input redirection without file name", FPRINTF);
      else if (syncheck == SYN_FAIL_INVALIDBG)
        errorPrint("Invalid use of background", FPRINTF);
      break;

    case LEX_QERROR:
      errorPrint("Invalid : Unmatched quote", FPRINTF);
      break;

    case LEX_NOMEM:
      errorPrint("Cannot allocate memory", FPRINTF);
      break;

    case LEX_LONG:
      errorPrint("Command is too large", FPRINTF);
      break;

    default:
      errorPrint("lexLine needs to be fixed", FPRINTF);
      exit(EXIT_FAILURE);
  }
}

int main() {
  
  char acLine[MAX_LINE_SIZE + 2];

  while (1) {
    fprintf(stdout,"%% ");
    fflush(stdout);
    if (fgets(acLine, MAX_LINE_SIZE, stdin) == NULL) {
      printf("\n");
      exit(EXIT_SUCCESS);
    }
    shellHelper(acLine);
  }
}

