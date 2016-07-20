  use Text::BibTeX;

  my($maxyear) = 2016;

  my(@types) = ("article", "inproceedings", "hdr", "phdthesis", "inbook", "book", "techreport");
  my(%pp_type) = (
    "inproceedings" => "Conference articles",
    "article" => "Journal articles",
    "phdthesis" => "PhD thesis",
    "hdr" => "Accreditation to Supervise Research (H.D.R.)",
    "inbook" => "Book chapters",
    "book" => "Books",
    "techreport" => "Technical reports",
    "others" => "Others",
    );

  sub uniq {
      my %seen;
      grep !$seen{$_}++, @_;
  }

  sub bibtable { 
      my $bibfile = shift;

      my(%count);

      @cats = ("core", "intra", "extern");

      my(%pp) = (
          "core" => "SimGrid as a scientific object",
          "extern" => "SimGrid as a scientific instrument",
          "intra" => "SimGrid as a scientific instrument",
          );

      foreach $cat (@cats) {
          foreach $year (2000..$maxyear) {
              $count{$pp{$cat}}{$year} = 0;
          }
      }

      while ($entry = new Text::BibTeX::Entry $bibfile) {
          next unless $entry->parse_ok;
          $year=$entry->get('year');
          $cat=$entry->get('category');
          $count{$pp{$cat}}{$year}+=1;
      }
      @years=();
      foreach $cat (keys %count) {
          @years = (@years, (keys %{$count{$cat}}));
      }
      @years = uniq(sort {$a <=> $b} @years);


      print "|-\n";
      print "| Year |".(join " | ",@years)." | Total |\n";
      print "|-\n";
      foreach $cat (uniq (values %pp)) {
          @val = ();
          $sum = 0;
          foreach $year (@years) {
              push @val, $count{$cat}{$year};
          }
          $sum += $_ for @val;
          print "| $cat |".(join " | ",@val)." | $sum \n";
      }
      print "|-\n";
  }

  sub bibtable_bytype {
      my $bibfile = shift;
      my $format = shift or "org";

      if($format eq "") { $format = "org"; }
      if(($format ne "org") && ($format ne "latex")) {
	  die "Invalid format '$format'\n";
      }

      my(%count);
      foreach $cat (@types, "others") {
          foreach $year (2000..$maxyear) {
              $cat{$cat}{$year} = 0;
          }
      }

      while ($entry = new Text::BibTeX::Entry $bibfile) {
          next unless $entry->parse_ok;
          $year=$entry->get('year');
          $cat=$entry->type;
	  if($cat eq "phdthesis") {
	      if(!($entry->get('type') =~ "Theses")) {
		  $cat = "hdr";
	      }
	  } elsif(!($cat ~~ @types)) { $cat = "others"; }
          $count{$cat}{$year}+=1;
      }

      @years=();
      foreach $cat (keys %count) {
          @years = (@years, (keys %{$count{$cat}}));
      }
      @years = uniq(sort {$a <=> $b} @years);


      if($format eq "org") {
	  print "|-\n";
	  print "| Year |".(join " | ",@years)." | Total |\n";
	  print "|-\n";
      } elsif($format eq "latex") {
	  open TABLE, "> liste_publications_table.tex";
	  print TABLE '\begin{center}\begin{tabular}{lrrrrr}\hline'."\n";
	  print TABLE '  & '.(join " & ",@years).' & Total \\\\\\hline'."\n";
      }
      foreach $cat (@types, "others") {
	  @val = ();
	  $sum = 0;
	  foreach $year (@years) {
	      push @val, $count{$cat}{$year};
	  }
	  $sum += $_ for @val;
	  if($sum==0) { next; }
	  print "| $pp_type{$cat} |".(join " | ",@val)." | $sum \n" if($format eq "org");
	  print TABLE "  $pp_type{$cat} &".(join " & ",@val)." & $sum ".'\\\\'."\n" if($format eq "latex");
      }
      if($format eq "org") {
	  print "|-\n";
	  print "| Total |";
      } elsif($format eq "latex") {
	  print TABLE '\\hline'."\n";
	  print TABLE ' Total &';
      }
      $s = 0;
      foreach $year (@years) {
	  $sum = 0;
	  @val = ();
	  foreach $cat (@types, "others") {
	      push @val, $count{$cat}{$year};
	  }
	  $sum += $_ for @val;
	  $s += $sum;
	  print " $sum | " if ($format eq "org");
	  print TABLE " $sum & " if ($format eq "latex")
      }
      if($format eq "org") {
	  print " $s |\n";
	  print "|-\n";
      } elsif($format eq "latex") {
	  print TABLE "$s ".'\\\\\\hline'."\n";
	  print TABLE '\end{tabular}\end{center}'."\n";
	  close TABLE;
      }
  }

  sub bibsplit {
      my $bibfile_name = shift;

      my(%count);
      foreach $cat (@types, "others") {
          foreach $year (2000..$maxyear) {
              $cat{$cat}{$year} = 0;
          }
      }
      my $bibfile = new Text::BibTeX::File($bibfile_name);
      while ($entry = new Text::BibTeX::Entry $bibfile) {
          next unless $entry->parse_ok;
          $year=$entry->get('year');
          $cat=$entry->type;
          if(!($cat ~~ @types)) { $cat = "others"; }
          $count{$cat}{$year}+=1;
      }

      @years=();
      foreach $cat (keys %count) {
          @years = (@years, (keys %{$count{$cat}}));
      }
      @years = uniq(sort {$b <=> $a} @years);

      open BIBLIO, "> liste_publications.tex";
      print BIBLIO '\\makeatletter
\\let\\jobname@sav=\\jobname
\\def\\jobname{liste_publications}
\\bibliographystyle{abbrv}
';
      $oldval = $pp_type{"phdthesis"};
      $pp_type{"phdthesis"} = "PhD thesis and Accreditation to Supervise Research (H.D.R.)";
      foreach $cat (@types, "others") {
	  @val = ();
	  $sum = 0;
	  $sum += $_ for (values(%{$count{$cat}}));
	  if($sum==0) {next;}
	  print BIBLIO '\\subsection*{'.$pp_type{$cat}."}\n";
	  foreach $year (@years) {
	      if($count{$cat}{$year}==0) { next; }
	      my $bibfile = new Text::BibTeX::File($bibfile_name);
	      $newfile_name = "$cat-$year.bib";

	      print BIBLIO "\\begin{btSect}{$newfile_name}\n";
	      print BIBLIO "\\subsubsection*{$year}\\btPrintAll"."\n".'\\end{btSect}'."\n\n";

	      $newfile = new Text::BibTeX::File "> $newfile_name";
	      while ($entry = new Text::BibTeX::Entry $bibfile)
	      {
		  next unless $entry->parse_ok;
		  my $thiscat=$entry->type;
		  if(!($thiscat ~~ @types)) { $thiscat = "others"; }

		  $entry->write ($newfile) if($entry->get('year') eq $year && 
					      $thiscat eq $cat);
	      }
	  }
      }
      $pp_type{"phdthesis"} = $oldval;
      print BIBLIO '\\let\\jobname=\\jobname@sav\\makeatother'."\n";
      close BIBLIO;
  }

  sub format_names {
      my $names = shift;
      my @names = split(/ and /, $names);
      return (join ", ",@names);
  }

  sub format_clean {
      my $str = shift;
      $str =~ s/[{}]*//g;
      $str =~ s/"//g;
      return $str;
  }

  sub format_links {
      my $entry = shift;
      my @output;
      if(defined($entry->get('pdf'))) {
          push @output, ("[[".$entry->get('pdf')."][PDF]] ");
      } 
      if(defined($entry->get('url'))) {
          push @output, ("[[".$entry->get('url')."][WWW]] ");
      } 
      if(defined($entry->get('doi'))) {
          $doi = $entry->get('doi');
          push @output, ("[[http://dx.doi.org/$doi][doi:$doi]] ");
      } 
      return @output;
  }

  sub format_journal {
      my $entry = shift;
      my @output=(format_names($entry->get('author')), ". *",$entry->get('title'),
                  "*. /",$entry->get('journal'),"/, ",
                  $entry->get('year'),". ");
      if(defined($entry->get('volume'))) { push @output, .$entry->get('volume').""; }
      if(defined($entry->get('number'))) { push @output, ("(".$entry->get('number').") "); }

      push @output, format_links($entry);
      return format_clean(join "", @output);
  }

  sub format_conf {
      my $entry = shift;
      my @output=(format_names($entry->get('author')), ". *",$entry->get('title'),
                  "*. In /",$entry->get('booktitle'),"/, ",
                  $entry->get('year'),". ");

      push @output, format_links($entry);
      return format_clean(join "", @output);
  }

  sub format_phdthesis {
      my $entry = shift;
      if(defined($entry->get('type'))) { $type = $entry->get('type'); }
      else { 
         $type = $entry->type;
         if($type =~ /phd/) { $type="PhD. thesis. " ; }
         elsif($type =~ /master/) { $type = "MSc. thesis. " ; }
      }
      my @output=(format_names($entry->get('author')), ". *",$entry->get('title'),
                  "*. $type. /",$entry->get('school'),"/, ",
                  $entry->get('year'),". ");

      push @output, format_links($entry);
      return format_clean(join "", @output);
  }

  sub format_techreport {
      my $entry = shift;
      my @output=(format_names($entry->get('author')), ". *",$entry->get('title'),
                  "*. /",$entry->get('institution'),"/, ",
                  $entry->get('year'),". ");
      if(defined($entry->get('type'))) { push @output, ($entry->get('type')." "); }
      if(defined($entry->get('number'))) { push @output, ("N° ".$entry->get('number')." "); }

      push @output, format_links($entry);
      return format_clean(join "", @output);
  }

  sub bibhtml {
      my $bibfile = shift;
      my $include_cat_pat = shift;
      my $include_type_pat = shift;

      while ($entry = new Text::BibTeX::Entry $bibfile) {
          next unless $entry->parse_ok;
          $cat = $entry->get('category');
          next unless $$include_cat_pat{$cat};
          next unless (!defined($include_type_pat) || $$include_type_pat{$entry->type});

          if($entry->type =~ /article/) {
              print "- ".(format_journal($entry))."\n";
          } elsif($entry->type =~ /inproceedings/) {
              print "- ".(format_conf($entry))."\n";
          } elsif($entry->type =~ /techreport/) {
              print "- ".(format_techreport($entry))."\n";
          } elsif($entry->type =~ /phdthesis/ || $entry->type =~ /mastersthesis/) {
              print "- ".(format_phdthesis($entry))."\n";
          } else {
              die "Unknown type ".$entry->type."\n";
          }
      }
  }

  # my $bibfile = new Text::BibTeX::File("all.bib");

  # bibhtml($bibfile,"core");

  1;
