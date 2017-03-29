%% LaTeX2e class for diploma theses
%% Based on wissdoc.cls by Roland Bless, 1996-2001
%% bless@telematik.informatik.uni-karlsruhe.de
%%
%% Adapted by: Timo Rohrberg, 2009
%% timo.rohrberg@student.kit.edu
%%
%% Additions by: Thorsten Haberecht, IPD - Chair Prof. Böhm, 2010
%% thorsten.haberecht@kit.edu
%%
%% Minor changes by: Moritz Baum, ITI, 2012
%% moritz.baum@kit.edu


\NeedsTeXFormat{LaTeX2e}                                        % We do need LaTeX2e
\ProvidesClass{thesisclass}
\LoadClass[a4paper,11pt,titlepage]{scrbook} % Class based on scrbook

\RequirePackage{ngerman}                                        % New german orthography



%% -------------------------------
%% |          Packages           |
%% -------------------------------

% Set document encoding to UTF-8.
\usepackage[utf8]{inputenc}
% \usepackage[latin1]{inputenc} % Input in ISO 8859-1 (Latin1)
% Use vector glyphs of Computer Modern font with T1 encoding.
\usepackage{lmodern}
\usepackage[T1]{fontenc}
% Activate micro-typographic improvements.
\usepackage[protrusion=true,expansion=true]{microtype}
% \usepackage{ae}               % Almost european, virtual T1-Font
% Activate color definitions.
\usepackage[pdftex]{xcolor}
% Make including other pdfs available.
\usepackage[pdftex]{graphicx}
% Additional math symbols.
\usepackage{amssymb,amsmath,amsthm}
% Smart spacing for macros.
\usepackage{xspace}
% Rotated table head labels.
\usepackage{rotating}
% Nice table separator lines.
\usepackage{booktabs}

\usepackage{vmargin}          % Adjust margins in a simple way
\usepackage{fancyhdr}         % Define simple headings
\usepackage{subfigure}
\usepackage{url}
\usepackage[absolute,overlay]{textpos}
\usepackage{tikz}
\usepackage[american,ngerman]{babel}
\usepackage[ruled, vlined, linesnumbered]{algorithm2e}
\usepackage[raiselinks=true,
                        bookmarks=true,
                        bookmarksopenlevel=1,
                        bookmarksopen=true,
                        bookmarksnumbered=true,
                        hyperindex=true,
                        plainpages=false,
                        pdfpagelabels=true,
                        pdfborder={0 0 0.5},
                        colorlinks=false,
                        linkbordercolor={0 0.61 0.50},
                        citebordercolor={0 0.61 0.50}]{hyperref}  %{0.57 0.74 0.57}

\usepackage[fixlanguage]{babelbib}  % sets german style for literature entries
\selectbiblanguage{ngerman}     % for \bibliographystyle{babalpha}
%% --- End of Packages ---



%% -------------------------------
%% |        Declarations         |
%% -------------------------------
\DeclareGraphicsExtensions{.svg}
%% --- End of Declarations ---



%% -------------------------------
%% |         New commands        |
%% -------------------------------
\newcommand{\changefont}[3]{\fontfamily{#1} \fontseries{#2} \fontshape{#3} \selectfont}
\newcommand{\chapterheadfont}{}
\newcommand{\blankpage}{
 \clearpage{\pagestyle{empty}\cleardoublepage}
}
%% --- End of New Commands ---



%% -------------------------------
%% |      Globale Settings       |
%% -------------------------------
\setcounter{secnumdepth}{3} % Numbering also for \subsubsections
\setcounter{tocdepth}{3}    % Register \subsubsections in content directory

\setpapersize{A4}
\setmarginsrb{3cm}{1cm}{3cm}{1cm}{6mm}{7mm}{5mm}{15mm}

\parindent 0cm                     % Do not indent beginning of paragraph
\parskip1.5ex plus0.5ex minus0.5ex % Margin between paragraphs
%% --- End of global Settings ---



%% -------------------------------
%% |          Headings           |
%% -------------------------------
\pagestyle{fancy}
\renewcommand{\chaptermark}[1]{\markboth{\thechapter.\ #1}{}}
\fancyhf{}
\fancyhead[RO]{\headfont\nouppercase{\rightmark}}   % Header for left page (odd)
\fancyhead[LE]{\headfont\nouppercase{\leftmark}}    % Header for right page (even)
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0.5pt}
\renewcommand{\footrulewidth}{0pt}
\fancypagestyle{plain}{%
\fancyhf{}                      % No Header and Footer fields
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}
\fancyfoot[C]{\thepage}
}
%% --- End of Headings ---



%% -------------------------------
%% |      Style of captions      |
%% -------------------------------
\renewcommand{\chaptername}{}

\renewcommand{\section}{%
\@startsection{section}%
{1}     % Structure level
{0mm}   % Indention
{3ex plus 1ex minus 1ex}        % Pre-Margin
{0.5ex plus 0.5ex minus 0.5ex}      % Post-Margin
{\chapterheadfont\Large\bfseries}   % Style
}
\renewcommand{\subsection}{%
\@startsection{subsection}%
{2}     % Structure level
{0mm}   % Indention
{3ex plus 1ex minus 0.5ex}        % Pre-Margin
{0.3ex plus 0.3ex minus 0.3ex}      % Post-Margin
{\chapterheadfont\large\bfseries}   % Style
}
\renewcommand{\subsubsection}{%
\@startsection{subsubsection}%
{3}     % Structure level
{0mm}   % Indention
{3ex plus 1ex minus 0.5ex}        % Pre-Margin
{0.2ex plus 0.2ex minus 0.2ex}      % Post-Margin
{\chapterheadfont\normalsize\bfseries}  % Style
}
\renewcommand{\paragraph}{%
\@startsection{paragraph}%
{4}     % Structure level
{0mm}   % Indention
{2.5ex plus 1ex minus 0.3ex}            % Pre-Margin
{0.2ex plus 0.2ex minus 0.2ex}          % Post-Margin
{\chapterheadfont\normalsize\bfseries}  % Style
}
\renewcommand{\subparagraph}{\@startsection
{subparagraph}% % the name
{5}% % the level
{0 pt}% % the indent
{5pt}% % the beforeskip
{-7pt}% % the afterskip
{\chapterheadfont\normalsize\bfseries}% % the style
}
%% --- End of captions style ---



%% ---------------------------------
%% |   Style of chapter captions   |
%% ---------------------------------
\newlength{\chapnolen}
\newlength{\chapparlen}
\newsavebox{\chapno}
\renewcommand{\@makechapterhead}[1]{
  \vspace*{0.2\textheight}
  \vskip 15\p@
  {\parindent \z@ \raggedright \normalfont
    \ifnum \c@secnumdepth >\m@ne
      \if@mainmatter
        \savebox{\chapno}{\chapterheadfont\huge\bfseries \thechapter.}
        \settowidth{\chapnolen}{\usebox{\chapno}}
        \parbox[t]{\chapnolen}{\usebox{\chapno}}\nobreak\leavevmode
      \fi
    \fi
    \interlinepenalty\@MM
    \setlength{\chapparlen}{\textwidth}
    \addtolength{\chapparlen}{-1.0\chapnolen}
    \addtolength{\chapparlen}{-2ex}
    \leavevmode\nobreak
    \parbox[t]{\chapparlen}{\raggedright\chapterheadfont\huge \bfseries #1\par\nobreak}
    \vskip 40\p@
  }}

\renewcommand{\@makeschapterhead}[1]{
  \vspace*{50\p@}
  {\parindent \z@ \raggedright
    \normalfont
    \interlinepenalty\@M
    \chapterheadfont \huge \bfseries  #1\par\nobreak
    \vskip 40\p@
  }
}
%% --- End of chapter captions style ---



%% ---------------------------------
%% |  Style of content directory   |
%% ---------------------------------
\let\oldtableofcontents\tableofcontents
\renewcommand{\tableofcontents}{{\pdfbookmark{\contentsname}{\contentsname}\chapterheadfont\oldtableofcontents}}
\let\@olddottedtocline\@dottedtocline
\renewcommand{\@dottedtocline}[5]{\@olddottedtocline{#1}{#2}{#3}{#4}{\chapterheadfont #5}}
%% --- End of content directory style ---


%% ----------------------------------
%% |  Style of appendix numbering   |
%% ----------------------------------
 \renewcommand\appendix{\par
   \setcounter{section}{0}%
   \setcounter{subsection}{0}%
   \setcounter{figure}{0}%
   \renewcommand\thesection{\Alph{section}}%
   \renewcommand\thefigure{\Alph{section}.\arabic{figure}}
   \renewcommand\thetable{\Alph{section}.\arabic{table}}}
%% --- End of appenix numbering style ---


%% ----------------------------------
%% |  Some additional options       |
%% ----------------------------------
\setlength{\algomargin}{2em}    % Leave space for line numbering
\numberwithin{algocf}{chapter}  % Algorithms numbered as Chapternumber.Algonumber
\clubpenalty = 10000        % Avoid widows and club lines
\widowpenalty = 10000
\displaywidowpenalty = 10000
\setkomafont{descriptionlabel}{\normalfont\bfseries}    % Normal Font in description environment
\addtokomafont{sectioning}{\normalfont\bfseries}    % Normal Font for table of contents

%% --- End of additional options ---


%% **** END OF CLASS ****
