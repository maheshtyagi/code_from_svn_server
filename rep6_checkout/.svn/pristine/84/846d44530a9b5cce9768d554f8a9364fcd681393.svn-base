
#TagParser - customized DOM parser for the utility.
#Created By:-Amit Kalia
#Date:-22/07/2012

package TagParser;
use 5.008_001;
use strict;
use Symbol ();
use Carp ();
use Encode ();

our $VERSION = "0.20";

my $SEC_OF_DAY = 60 * 60 * 24;

#  [000]        '/' if closing tag.
#  [001]        tagName
#  [002]        attributes string (with trailing /, if self-closing tag).
#  [003]        content until next (nested) tag.
#  [004]        attributes hash cache.
#  [005]        innerText combined strings cache.
#  [006]        index of matching closing tag (or opening tag, if [000]=='/')
#  [007]        index of parent (aka container) tag.
#
sub new {
    my $package = shift;
    my $src     = shift;
    my $self    = {};
    bless $self, $package;
    return $self unless defined $src;

    if ( $src =~ m#^https?://\w# ) {
        $self->fetch( $src, @_ );
    }
    elsif ( $src !~ m#[<>|]# && -f $src ) {
        $self->open($src);
    }
    elsif ( $src =~ /<.*>/ ) {
        $self->parse($src);
    }

    $self;
}

sub fetch {
    my $self = shift;
    my $url  = shift;
    if ( !defined $URI::Fetch::VERSION ) {
        local $@;
        eval { require URI::Fetch; };
        Carp::croak "URI::Fetch is required: $url" if $@;
    }
    my $res = URI::Fetch->fetch( $url, @_ );
    Carp::croak "URI::Fetch failed: $url" unless ref $res;
    return if $res->is_error();
    $self->{modified} = $res->last_modified();
    my $text = $res->content();
    $self->parse( \$text );
}

sub open {
    my $self = shift;
    my $file = shift;
    my $text = TagParser::Util::read_text_file($file);
    return unless defined $text;
    my $epoch = ( time() - ( -M $file ) * $SEC_OF_DAY );
    $epoch -= $epoch % 60;
    $self->{modified} = $epoch;
    $self->parse( \$text );
}

sub parse {
    my $self   = shift;
    my $text   = shift;
    my $txtref = ref $text ? $text : \$text;

    my $charset = TagParser::Util::find_meta_charset($txtref);
    $self->{charset} ||= $charset;
    if ($charset && Encode::find_encoding($charset)) {
        TagParser::Util::encode_from_to( $txtref, $charset, "utf-8" );
    }
    my $flat = TagParser::Util::html_to_flat($txtref);
    Carp::croak "Null HTML document." unless scalar @$flat;
    $self->{flat} = $flat;
    scalar @$flat;
}

sub getElementsByTagName {
    my $self    = shift;
    my $tagname = lc(shift);

    my $flat = $self->{flat};
    my $out = [];
    for( my $i = 0 ; $i <= $#$flat ; $i++ ) {
        next if ( $flat->[$i]->[001] ne $tagname );
        next if $flat->[$i]->[000];                 # close
        my $elem = TagParser::Element->new( $flat, $i );
        return $elem unless wantarray;
        push( @$out, $elem );
    }
    return unless wantarray;
    @$out;
}

sub getElementsByAttribute {
    my $self = shift;
    my $key  = lc(shift);
    my $val  = shift;

    my $flat = $self->{flat};
    my $out  = [];
    for ( my $i = 0 ; $i <= $#$flat ; $i++ ) {
        next if $flat->[$i]->[000];    # close
        my $elem = TagParser::Element->new( $flat, $i );
        my $attr = $elem->attributes();
        next unless exists $attr->{$key};
        next if ( $attr->{$key} ne $val );
        return $elem unless wantarray;
        push( @$out, $elem );
    }
    return unless wantarray;
    @$out;
}

sub getElementsByClassName {
    my $self  = shift;
    my $class = shift;
    return $self->getElementsByAttribute( "class", $class );
}

sub getElementsByName {
    my $self = shift;
    my $name = shift;
    return $self->getElementsByAttribute( "name", $name );
}

sub getElementById {
    my $self = shift;
    my $id   = shift;
    return scalar $self->getElementsByAttribute( "id", $id );
}

sub modified {
    $_[0]->{modified};
}

# ----------------------------------------------------------------

package TagParser::Element;
use strict;

sub new {
    my $package = shift;
    my $self    = [@_];
    bless $self, $package;
    $self;
}

sub tagName {
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    return $flat->[$cur]->[001];
}

sub id {
    my $self = shift;
    $self->getAttribute("id");
}

sub getAttribute {
    my $self = shift;
    my $name = lc(shift);
    my $attr = $self->attributes();
    return unless exists $attr->{$name};
    $attr->{$name};
}

sub innerText {
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];
    return $elem->[005] if defined $elem->[005];    # cache
    return if $elem->[000];                         # </xxx>
    return if ( defined $elem->[002] && $elem->[002] =~ m#/$# ); # <xxx/>

    my $tagname = $elem->[001];
    my $closing = TagParser::Util::find_closing($flat, $cur);
    my $list    = [];
    for ( ; $cur < $closing ; $cur++ ) {
        push( @$list, $flat->[$cur]->[003] );
    }
    my $text = join( "", grep { $_ ne "" } @$list );
    $text =~ s/^\s+|\s+$//sg;
#   $text = "" if ( $cur == $#$flat );              # end of source
    $elem->[005] = TagParser::Util::xml_unescape( $text );
}

sub subTree
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];
    return if $elem->[000];                         # </xxx>
    my $closing = TagParser::Util::find_closing($flat, $cur);
    my $list    = [];
    while (++$cur < $closing)
      {
        push @$list, $flat->[$cur];
      }

    # allow the getElement...() methods on the returned object.
    return bless { flat => $list }, 'TagParser';
}


sub nextSibling
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];

    return undef if $elem->[000];                         # </xxx>
    my $closing = TagParser::Util::find_closing($flat, $cur);
    my $next_s = $flat->[$closing+1];
    return undef unless $next_s;
    return undef if $next_s->[000];     # parent's </xxx>
    return TagParser::Element->new( $flat, $closing+1 );
}

sub firstChild
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];
    return undef if $elem->[000];                         # </xxx>
    my $closing = TagParser::Util::find_closing($flat, $cur);
    return undef if $closing <= $cur+1;                 # no children here.
    return TagParser::Element->new( $flat, $cur+1 );
}

sub childNodes
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $child = firstChild($self);
    return [] unless $child;    # an empty array is easier for our callers than undef
    my @c = ( $child );
    while (defined ($child = nextSibling($child)))
      {
        push @c, $child;
      }
    return \@c;
}

sub lastChild
{
    my $c = childNodes(@_);
    return undef unless $c->[0];
    return $c->[-1];
}

sub previousSibling
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;

    ## This one is expensive.
    ## We use find_closing() which walks forward.
    ## We'd need a find_opening() which walks backwards.
    ## So we walk backwards one by one and consult find_closing()
    ## until we find $cur-1 or $cur.

    my $idx = $cur-1;
    while ($idx >= 0)
      {
        if ($flat->[$idx][000] && defined($flat->[$idx][006]))
          {
            $idx = $flat->[$idx][006];  # use cache for backwards skipping
            next;
          }

        my $closing = TagParser::Util::find_closing($flat, $idx);
        return TagParser::Element->new( $flat, $idx )
          if defined $closing and ($closing == $cur || $closing == $cur-1);
        $idx--;
      }
    return undef;
}

sub parentNode
{
    my $self = shift;
    my ( $flat, $cur ) = @$self;

    return TagParser::Element->new( $flat, $flat->[$cur][007]) if $flat->[$cur][007];     # cache

    ##
    ## This one is very expensive.
    ## We use previousSibling() to walk backwards, and
    ## previousSibling() is expensive.
    ##
    my $ps = $self;
    my $first = $self;

    while (defined($ps = previousSibling($ps))) { $first = $ps; }

    my $parent = $first->[1] - 1;
    return undef if $parent < 0;
    die "parent too short" if TagParser::Util::find_closing($flat, $parent) <= $cur;

    $flat->[$cur][007] = $parent;       # cache
    return TagParser::Element->new( $flat, $parent )
}

##
## feature:
## self-closing tags have an additional attribute '/' => '/'.
##
sub attributes {
    my $self = shift;
    my ( $flat, $cur ) = @$self;
    my $elem = $flat->[$cur];
    return $elem->[004] if ref $elem->[004];    # cache
    return unless defined $elem->[002];
    my $attr = {};
    while ( $elem->[002] =~ m{
        ([^\s="']+)(\s*=\s*(?:["']((?(?<=")(?:\\"|[^"])*?|(?:\\'|[^'])*?))["']|([^'"\s=]+)['"]*))?
    }sgx ) {
        my $key  = $1;
        my $test = $2;
        my $val  = $3 || $4;
        my $lckey = lc($key);
        if ($test) {
            $key =~ tr/A-Z/a-z/;
            $val = TagParser::Util::xml_unescape( $val );
            $attr->{$lckey} = $val;
        }
        else {
            $attr->{$lckey} = $key;
        }
    }
    $elem->[004] = $attr;    # cache
    $attr;
}

# ----------------------------------------------------------------

package TagParser::Util;
use strict;

sub xml_unescape {
    my $str = shift;
    return unless defined $str;
    $str =~ s/&quot;/"/g;
    $str =~ s/&lt;/</g;
    $str =~ s/&gt;/>/g;
    $str =~ s/&amp;/&/g;
    $str;
}

sub read_text_file {
    my $file = shift;
    my $fh   = Symbol::gensym();
    open( $fh, $file ) or Carp::croak "$! - $file\n";
    local $/ = undef;
    my $text = <$fh>;
    close($fh);
    $text;
}

sub html_to_flat {
    my $txtref = shift;    # reference
    my $flat   = [];
    pos($$txtref) = undef;  # reset matching position
    while ( $$txtref =~ m{
        (?:[^<]*) < (?:
            ( / )? ( [^/!<>\s"'=]+ )
            ( (?:"[^"]*"|'[^']*'|[^"'<>])+ )?
        |
            (!-- .*? -- | ![^\-] .*? )
        ) > ([^<]*)
    }sxg ) {
        #  [000]  $1  close
        #  [001]  $2  tagName
        #  [002]  $3  attributes
        #         $4  comment element
        #  [003]  $5  content
        next if defined $4;
        my $array = [ $1, $2, $3, $5 ];
        $array->[001] =~ tr/A-Z/a-z/;
        #  $array->[003] =~ s/^\s+//s;
        #  $array->[003] =~ s/\s+$//s;
        push( @$flat, $array );
    }
    $flat;
}

## returns 1 beyond the end, if not found.
## returns undef if called on a </xxx> closing tag
sub find_closing
{
  my ($flat, $cur) = @_;

  return $flat->[$cur][006]        if   $flat->[$cur][006];     # cache
  return $flat->[$cur][006] = $cur if (($flat->[$cur][002]||'') =~ m{/$});    # self-closing

  my $name = $flat->[$cur][001];
  my $pre_nest = 0;
  ## count how many levels deep this type of tag is nested.
  my $idx;
  for ($idx = 0; $idx <= $cur; $idx++)
    {
      my $e = $flat->[$idx];
      next unless   $e->[001] eq $name;
      next if     (($e->[002]||'') =~ m{/$});   # self-closing
      $pre_nest += ($e->[000]) ? -1 : 1;
      $pre_nest = 0 if $pre_nest < 0;
      $idx = $e->[006]-1 if !$e->[000] && $e->[006];    # use caches for skipping forward.
    }
  my $last_idx = $#$flat;

  ## we move last_idx closer, in case this container
  ## has not all its subcontainers closed properly.
  my $post_nest = 0;
  for ($idx = $last_idx; $idx > $cur; $idx--)
    {
      my $e = $flat->[$idx];
      next unless    $e->[001] eq $name;
      $last_idx = $idx-1;               # remember where a matching tag was
      next if      (($e->[002]||'') =~ m{/$});  # self-closing
      $post_nest -= ($e->[000]) ? -1 : 1;
      $post_nest = 0 if $post_nest < 0;
      last if $pre_nest <= $post_nest;
      $idx = $e->[006]+1 if $e->[000] && defined $e->[006];     # use caches for skipping backwards.
    }

  my $nest = 1;         # we know it is not self-closing. start behind.

  for ($idx = $cur+1; $idx <= $last_idx; $idx++)
    {
      my $e = $flat->[$idx];
      next unless    $e->[001] eq $name;
      next if      (($e->[002]||'') =~ m{/$});  # self-closing
      $nest      += ($e->[000]) ? -1 : 1;
      if ($nest <= 0)
        {
          die "assert </xxx>" unless $e->[000];
          $e->[006] = $cur;     # point back to opening tag
          return $flat->[$cur][006] = $idx;
        }
      $idx = $e->[006]-1 if !$e->[000] && $e->[006];    # use caches for skipping forward.
    }

  # not all closed, but cannot go further
  return $flat->[$cur][006] = $last_idx+1;
}

sub find_meta_charset {
    my $txtref = shift;    # reference
    while ( $$txtref =~ m{
        <meta \s ((?: [^>]+\s )? http-equiv\s*=\s*['"]?Content-Type [^>]+ ) >
    }sxgi ) {
        my $args = $1;
        return $1 if ( $args =~ m# charset=['"]?([^'"\s/]+) #sxgi );
    }
    undef;
}

sub encode_from_to {
    my ( $txtref, $from, $to ) = @_;
    return     if ( $from     eq "" );
    return     if ( $to       eq "" );
    return $to if ( uc($from) eq uc($to) );
    Encode::from_to( $$txtref, $from, $to, Encode::XMLCREF() );
    return $to;
}

# ----------------------------------------------------------------
1;
# ----------------------------------------------------------------
