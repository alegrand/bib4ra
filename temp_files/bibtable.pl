    use Text::BibTeX;
    require "bibtex.pl";

    $biblio = "mescal.bib";

    my $bibfile = new Text::BibTeX::File($biblio);
    bibtable_bytype($bibfile,"latex");
