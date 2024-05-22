#!/usr/bin/env perl
my $threshold=$ARGV[0];
while($line=<STDIN>){
  chomp($line);
  push(@lines,$line);
}
my $current_count;
my $current_support;
my $minjcov;
my %maxjcov=();
for($j=0;$j<=$#lines;$j++){
  @F=split(/\t/,$lines[$j]);
  if($F[2] eq "transcript"){
    my ($transcript_id_,$geneID_,$count_,$support_,$full_cov_,$cov_junc_)=parse_transcript_attr($F[8]);
    $transcripts_at_gene{$geneID}.="$transcript_id_ ";
    $count{$transcript_id}=$count_;
    $total_count[int($count_)]++;
    $support{$transcript_id}=$support_;
    $full_cov{$transcript_id}=$full_cov_;
    $cov_junc{$transcript_id}=$cov_junc_;
  }
}

#compute threshold for the count
$thresh=0;
for($i=0;$i<$#total_count;$i++){
  $thresh+=$i*$total_count[$i];
}
$thresh*=$threshold;
$min_count=0;
$n=0;
for($i=0;$i<$#total_count;$i++){
  $n+=$i*$total_count[$i];
  if($n>$thresh && defined($total_count[$i])){
    $min_count=$i;
    $i=$#total_count;
  }
}

#process gene loci and compute max coverage at each locus
foreach $g(keys %transcripts_at_gene){
  my @transc=split(/\s+/,$transcripts_at_gene{$g});
  my $max_coverage=0;
  foreach $t(@transc){
    $max_coverage=$full_cov{$t} if($full_cov{$t}>$max_coverage);
  }
  $max_locus_coverage{$g}=$max_coverage;
}

print "# gff\n# min_count $min_count\n";
for($j=0;$j<=$#lines;$j++){
  @F=split(/\t/,$lines[$j]);
  if($F[2] eq "transcript"){
    my ($transcript_id_,$geneID_,$count_,$support_,$full_cov_,$cov_junc_)=parse_transcript_attr($F[8]);
    $flag=($count_> $min_count && $full_cov_> 0.5*$max_locus_coverage{$geneID_}) ? 1 : 0;
  }
  print $lines[$j],"\n" if($flag);
}




sub parse_transcript_attr{
  my @f=split(/;/,$_[0]);
  my ($transcript_id,$geneID,$count,$support,$full_cov,$cov_junc);
  for($i=0;$i<=$#f;$i++){
    if($f[$i] =~ /^transcript_id=/){
      @ff=split(/=/,$f[$i]);
      $transcript_id=$ff[1]
    }elsif($f[$i] =~ /^geneID=/){
      @ff=split(/=/,$f[$i]);
      $geneID=$ff[1];
    }elsif($f[$i] =~ /^read_num=/){
      @ff=split(/=/,$f[$i]);
      $count=$ff[1];
    }elsif($f[$i] =~ /^transcript_support=/){
      @ff=split(/=/,$f[$i]);
      $support=$ff[1];
    }elsif($f[$i] =~ /^full_junction_reads_coverage=/){
      @ff=split(/=/,$f[$i]);
      $full_cov=$ff[1];
    }elsif($f[$i] =~ /^covered_junctions=/){
      @ff=split(/=/,$f[$i]);
      @fff=split(/\//,$ff[1]);
      $cov_junc=1;
      $cov_junc=$fff[0]/$fff[1] if($fff[1]>0);
    }
  }
  return($transcript_id,$geneID,$count,$support,$full_cov,$cov_junc);
}

