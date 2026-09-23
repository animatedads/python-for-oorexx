/*----------------------------------------------------------------------------*/
/* smoke.rex                                                                  */
/*                                                                            */
/* Minimal end-to-end qualification for the rewrite.  A successful run proves*/
/* that ooRexx loaded the native package, CPython loaded orxpython.py, and a   */
/* Python logging.Logger was represented by a Rexx .Python proxy identity.    */
/*----------------------------------------------------------------------------*/

logger = .Python~getLogger('linux-rewrite-smoke')
if logger~id = 0 then raise syntax 93.900 array ('orxpython returned identity 0')

say 'rewrite-linux-ok id=' logger~id

::requires 'orxpython.cls'
