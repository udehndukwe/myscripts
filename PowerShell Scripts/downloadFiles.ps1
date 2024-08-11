$downloadLinks = (Invoke-WebRequest -Uri 'https://100gigs.org/').Links

foreach ($link in $links) {
    $name = $link.href.Replace("https://d86qu01cbyv4o.cloudfront.net/", "").Replace("https://d1eg7ouxwwgt8e.cloudfront.net/", "").Replace("/"."")    
    Invoke-WebRequest $link.href -OutFile .\$name
}


$downloadLinks.href

$links = @('https://d86qu01cbyv4o.cloudfront.net/ABBEY_ROAD/Ashley_Cole.zip'
    'https://d86qu01cbyv4o.cloudfront.net/AIR DRAKE/Tour Content.zip'
    'https://d86qu01cbyv4o.cloudfront.net/AIR DRAKE/_PLANE MISC.zip'
    'https://d86qu01cbyv4o.cloudfront.net/ARCHITECTURE/40 - YOLO ESTATE.zip'
    'https://d86qu01cbyv4o.cloudfront.net/ARCHITECTURE/NOEL - LONDON.zip'
    'https://d86qu01cbyv4o.cloudfront.net/BARBADOS/40_BEAT_PACK.zip'
    'https://d86qu01cbyv4o.cloudfront.net/BARBADOS/HOUSE.zip'
    'https://d86qu01cbyv4o.cloudfront.net/VIDEOS_OF_VIDEOS/JUMBOTRON.zip'
    'https://d86qu01cbyv4o.cloudfront.net/VIDEOS_OF_VIDEOS/STICKY.zip'
    'https://d86qu01cbyv4o.cloudfront.net/WICKHAM_WICKEM/NIGHT OWL.zip')