  use Text::BibTeX;
  require "bibtex.pl";

  $biblio = "mescal.bib";

  my $bibfile = new Text::BibTeX::File($biblio);
  bibtable_bytype($bibfile,"latex");
  bibsplit($biblio);
  system("rm publis.aux liste_publications*.blg liste_publications*.bbl");
  $lof = `pdflatex -interaction nonstopmode publis.tex 2>/dev/null | grep -e liste_publication | grep bibtopic | sed 's/.*liste/liste/'`;
  foreach $i (split "\n",$lof) {
      system "bibtex $i 2>/dev/null";
  }
  system "pdflatex -interaction nonstopmode publis.tex";
  system "pdflatex -interaction nonstopmode publis.tex";
