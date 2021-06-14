grammar Cactus;

//export CLASSPATH=".:/usr/share/java/antlr4-runtime-4.7.2.jar:$CLASSPATH"
//export CLASSPATH=".:/usr/share/java/antlr4-4.7.2.jar:$CLASSPATH"
//export CLASSPATH=".:/usr/share/java/antlr4-runtime.jar:$CLASSPATH"
//alias grun='java org.antlr.v4.gui.TestRig'
//antlr4 Cactus.g4
//javac Cactus*.java
//grun Cactus program -tree
//Parser rules

//parser rules : program
program : PROGRAM ID BEGIN
    {
        System.out.println("\t" + ".data");
    }
    declarations
    {
        System.out.println("\t" + ".text");
        System.out.println("main:");
    }
    statements[0 , 1] END
    {
        System.out.println("\tli \$v0, 10");
        System.out.println("\tsyscall");
    }
    ;

//parser rule : declarations
declarations : declarations_E ;

//parser rule : declarations_E
declarations_E :
    VAR
    ID
    {
        System.out.println( $ID.text + ": " + ".word 0");
    }
    declarations_E | ;

//parser rule : statements
statements[int reg , int label] returns [int nreg , int nlabel ] : ste = statements_E[$reg , $label] {$nreg = $ste.nreg ; $nlabel = $ste.nlabel;};

//parser rule : statements_E
statements_E[int reg , int label] returns [int nreg , int nlabel ] :
    st = statement[$reg , $label] { $reg = $st.nreg; $label = $st.nlabel; } ste = statements_E[$reg , $label] {$nreg = $ste.nreg; $nlabel = $ste.nlabel;}
    | {$nreg = $reg; $nlabel = $label;};

//parser rule : statement
statement[int reg , int label] returns [int nreg , int nlabel]:
    SET
    ID
    ASSIGN
    as = arithmeticExpression[$reg]
    {
        $reg = $as.nreg;
        System.out.println("\tla \$t" + $reg + ", " + $ID.text);
        $nreg = $reg - 1;
        System.out.println("\tsw \$t" + $nreg + ", 0(\$t" + $reg + ")");
        $nlabel = $label;
    }
    |
    IF be = booleanExpression[$reg , $label , $label + 1 , $label + 2]
    THEN
    {
        $nlabel = $be.nlabel;
        System.out.println("L" + $label + ":");
        $label = $label + 1;
    }
    st = statements[$reg , $nlabel]
    ENDIF
    {
        System.out.println("L" + $label +":");
        $nreg = $st.nreg;
        $nlabel = $st.nlabel;
    }
    |
    IF be = booleanExpression[$reg , $label , $label + 1 , $label + 2]
    THEN
    {
        $nlabel = $be.nlabel;
        System.out.println("L" + $label + ":");
        $label = $label + 1;
    }
    st = statements[$reg , $nlabel]
    ELSE
    {
        System.out.println("\tb	L"+($label+1));
        System.out.println("L"+$label+":");
        $label=$label+1;
    }
    st = statements[$reg , $label]
    ENDIF
    {
        System.out.println("L" + $label + ":");
        $nlabel = $st.nlabel + 1;
    }
    |
    WHILE
    {
        System.out.println("L" + $label + ":");
        $label = $label + 1;
    }
    be = booleanExpression[$reg , $label , $label + 1 , $label + 2]
    {
        $nlabel = $be.nlabel;
        System.out.println("L" + $label + ":");
        $label = $label + 1;
    }
    DO st = statements[$reg , $nlabel]
    {
        System.out.println("\tb   L" + ($label-2));
        System.out.println("L" + $label + ":");
        $nreg = $st.nreg;
        $nlabel = $st.nlabel;
    }
    ENDWHILE
    |
    READ ID
    {
        System.out.println("\tli \$v0, 5");
        System.out.println("\tsyscall");
        System.out.println("\tla \$t" + $reg + ", " + $ID.text);
        System.out.println("\tsw \$v0" + ", 0(\$t" + $reg + ")");
        $nreg = $reg;
        $nlabel = $label;
    }
    |
    WRITE ate = arithmeticExpression[$reg]
    {
        System.out.println("\tmove \$a0, \$t" + $reg);
        System.out.println("\tli \$v0, 1");
        System.out.println("\tsyscall");
        $nreg = $ate.nreg;
        $nlabel = label;
    }
    |
    EXIT
    {
        System.out.println("\tli \$v0, 10");
        System.out.println("\tsyscall");
        $nreg = $reg;
        $nlabel = $label;
    }
    ;

//parser rule : booleanExpression
booleanExpression[int reg , int t , int f , int label] returns [int nreg , int nlabel] :
bt = booleanTerm[$reg , $t , $f , $label]
    {
        $reg = $bt.nreg;
        System.out.println(" \$t" + ($reg - 1) + " \$t" + $reg + ", L" + $t);
        $reg = $reg - 1;
        $label = $bt.nlabel;
    }
    bee = booleanExpressio_E[$reg , $t , $f , $label]
    {
        System.out.println("\tb L" + $f);
        $nlabel = $bee.nlabel;
    }
    ;

//parser rule : booleanExpressio_E
booleanExpressio_E[int reg , int t , int f , int label] returns [int nreg , int nlabel] :
    {
        System.out.println("\tb L"+ $label);
        System.out.println("L" + $label + ":");
        $label = $label + 1;
    }
    OR bt = booleanTerm[$reg , $t , $f , $label] bee = booleanExpressio_E[$reg , $t , $f , $label]
    {
        System.out.println(" \$t0"+", \$t1"+", L"+$t);
        $nlabel=$bee.nlabel;
    } | { $nreg=$reg; $nlabel=$label; };

//parser rule : booleanTerm
booleanTerm[int reg , int t , int f , int label] returns [int nreg , int nlabel] :
    bf = booleanFactor[reg , $t , $f] {$reg = $bf.nreg;} bte = booleanTerm_E[$reg , $t , $f , $label] {$nreg = $bte.nreg; $nlabel = $bte.nlabel;};

//parser rule : booleanTerm_E
booleanTerm_E[int reg , int t , int f , int label] returns [int nreg , int nlabel] :
    {
        System.out.println(" \$t" + ($reg - 1) + " \$t" + $reg + ", L" + $label);
        $reg = $reg - 1;
        System.out.println("\tb L" + $f);
        System.out.println("L" + $label + ":");
        $label = $label + 1;
    }
    AND bf = booleanFactor[$reg , $t , $f] { $reg = $bf.nreg; }
    bte = booleanTerm_E[$reg , $t , $f , $label]  {$nreg = $bte.nreg; $nlabel = $bte.nlabel;}
    | {$nreg = $reg; $nlabel = $label;};

//parser rule : booleanFactor
booleanFactor[int reg  , int t , int f] returns [int nreg , int label]:
    NOT bf = booleanFactor[$reg , $f , $t]{$nreg = $bf.nreg;}
    | re = relationExpression[$reg , $t , $f]{$nreg = $re.nreg;};

//parser rule : relationExpression
relationExpression[int reg , int t , int f] returns [int nreg , int nlabel]:
    ate = arithmeticExpression[$reg] {$reg = $ate.nreg;} EQ ate = arithmeticExpression[$reg] {System.out.print("\tbeq"); $nreg = $reg;}
    | ate = arithmeticExpression[$reg] {$reg = $ate.nreg;} ABRACKET ate = arithmeticExpression[$reg] {System.out.print("\tbeq"); $nreg = $reg;}
    | ate = arithmeticExpression[$reg] {$reg = $ate.nreg;} GT ate = arithmeticExpression[$reg] {System.out.print("\tbgt"); $nreg = $reg;}
    | ate = arithmeticExpression[$reg] {$reg = $ate.nreg;} GE ate = arithmeticExpression[$reg] {System.out.print("\tbge"); $nreg = $reg;}
    | ate = arithmeticExpression[$reg] {$reg = $ate.nreg;} LT ate = arithmeticExpression[$reg] {System.out.print("\tblt"); $nreg = $reg;}
    | ate = arithmeticExpression[$reg] {$reg = $ate.nreg;} LE ate = arithmeticExpression[$reg] {System.out.print("\tble"); $nreg = $reg;};

//parser rule : arithmeticExpression
arithmeticExpression [ int reg ] returns [ int nreg ] : att = arithmeticTerm[$reg] { $reg = $att.nreg; } ate = arithmeticExpression_E[$reg] { $nreg = $ate.nreg; };

//parser rule : arithmeticExpression_E
arithmeticExpression_E [ int reg ] returns [ int nreg ] :
    ADD
    att = arithmeticTerm[$reg] {
        $reg = $att.nreg;
        System.out.println("\tadd \$t" + ($reg - 2) + ", " + "\$t" + ($reg - 2) + ", " +  "\$t" + ($reg-1));
        $reg = $reg - 1;
    }
    atee = arithmeticExpression_E[$reg] {$nreg = $atee.nreg;}
    |
    SUB
    att = arithmeticTerm[$reg] {
        $reg = $att.nreg;
        System.out.println("\tsub \$t" + ($reg - 2) + ", " + "\$t" + ($reg - 2) + ", " +  "\$t" + ($reg-1));
        $reg = $reg - 1;
    }
    atee = arithmeticExpression_E[$reg] {$nreg = $atee.nreg;}
    | {$nreg = $reg;};


//parser rule : arithmeticTerm
arithmeticTerm[ int reg ] returns [ int nreg ] : atf = arithmeticFactor[$reg] { $reg = $atf.nreg; } atfe = arithmeticTerm_E[$reg] { $nreg = $atfe.nreg; };

//parser rule : arithmeticTerm_E
arithmeticTerm_E[ int reg ] returns [ int nreg ] :
    MUL atf = arithmeticFactor[$reg]
    {
        $reg = $atf.nreg;
        System.out.println("\tmul \$t" + ($reg - 2) + ", " + "\$t" + ($reg - 2) + ", " +  "\$t" + ($reg-1));
        $reg = $reg - 1;
    }
    ate = arithmeticTerm_E[$reg] { $nreg = $ate.nreg; }
    |
    DIV atf = arithmeticFactor[$reg]
    {
        $reg = $atf.nreg;
        System.out.println("\tdiv \$t" + ($reg - 2) + ", " + "\$t" + ($reg - 2) + ", " +  "\$t" + ($reg-1));
        $reg = $reg - 1;
    }
    ate = arithmeticTerm_E[$reg] { $nreg = $ate.nreg; }
    |
    MOD atf = arithmeticFactor[$reg]
    {
        $reg = $atf.nreg;
        System.out.println("\trem \$t" + ($reg - 2) + ", " + "\$t" + ($reg - 2) + ", " +  "\$t" + ($reg-1));
        $reg = $reg - 1;
    }
    ate = arithmeticTerm_E[$reg] { $nreg = $ate.nreg; }
    | {$nreg = $reg;};

//parser rule : arithmeticFactor
arithmeticFactor[int reg] returns [int nreg] :
    SUB
    af = arithmeticFactor[$reg]
    {
        $nreg = $af.nreg;
        System.out.println("\tneg \$t" + ($nreg - 1) + ", " + "\$t" + ($nreg - 1));
    }
    | pe = primaryExpression[$reg] {$nreg = $pe.nreg;};

    //parser rule : primaryExpression
    primaryExpression[int reg] returns [int nreg] :
    CONST
    {
        System.out.println("\tli \$t" + $reg + ", " + $CONST.text);
        $nreg=$reg+1;
    }
    |
    ID
    {
        System.out.println("\tla \$t" + $reg + ", " + $ID.text);
        System.out.println("\tlw \$t" + $reg + ", " + "0(\$t" + $reg + ")");
        $nreg=$reg+1;
    }
    |
    LBRACKET
    ae = arithmeticExpression[$reg]
    RBRACKET {$nreg = $ae.nreg;};

//Lexer rules

BEGIN : 'Begin';
END : 'End';
PROGRAM : 'Program';
VAR : 'Var';
SET : 'Set';

AND: 'And'| '&&';
DO: 'Do';
ELSE: 'Else';
ENDIF: 'EndIf';
ENDWHILE: 'EndWhile';
EXIT: 'Exit';
IF: 'If';
NOT: 'Not'| '!';
OR: 'Or'| '||';
READ: 'Read';
THEN: 'Then';
WHILE: 'While';
WRITE: 'Write';

ID : [a-zA-Z_]+[a-zA-Z_0-9]*;
CONST:([0])|([-]?[1-9][0-9]*);

ADD:'+';
SUB:'-';
MUL:'*';
DIV:'/';
MOD:'%';
ASSIGN:'=';
EQ:'==';
ABRACKET:'<>';
GE:'>=';
GT:'>';
LE:'<=';
LT:'<';
LBRACKET:'(';
RBRACKET:')';

// Tab & Space & Newline
SPACE: [ \t\n\r]+-> channel(HIDDEN);

// Note Comment
COMMENT: '//'.*?'\n'-> channel(HIDDEN);



