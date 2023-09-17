---
layout: post
title: CS Papers - BitTorrent
category: en
---

<p class="meta">18 January 2012 - Lisbon</p>

## 1 Introduction

Original paper is [here](http://bittorrent.org/bittorrentecon.pdf).  As you know
BitTorrent is [Peer-to-Peer](http://en.wikipedia.org/wiki/Peer-to-peer) file
sharing protocol. <!--In this blog I will try to give brief summary of this
protocol.-->

## 2 Technical Framework

### 2.1 Publishing Content

The <code>.torrent</code> file contains information about the file, its length,
name, hashing information and url of a tracker. Trackers are responsible for
helping downloaders to find each other. A downloader sends information about
what file it is downloading, what port it's listening on, and tracker responds
with a list of contact information for peers which are downloading the same
file. Downloaders use this information to find and connect to each other. To
make a file available, a 'downloader' which happens to have the complete file,
known as seed, must be started.

### 2.2 Peer Distribution

The tracker's responsibilities are strictly limited to helping peers to find
each other.  All logistical problems of file downloading are handled in the
interactions between peers.  In order to keep track of which peers have what,
BitTorrent cuts files into pieces of fixed size. Each downloader reports to all
of its peers what pieces it has. To verify data integrity,
[SHA1](http://en.wikipedia.org/wiki/SHA-1) hashes of all pieces are included in
the <code>.torrent</code> file, and peers don't report that they have a piece
until they've checked the hash. Peers continuously download pieces from all
peers which they can.

### 2.3 Pipelining

BitTorrent facilitates the pipelining by breaking pieces further into sub-pieces
over the wire, typically sixteen kilobytes in size, and always keeping some
number, typically five, requests pipelined at once. This will avoid a delay
between pieces being sent, which is disastrous for transfer rates. The number
for pipelining can be selected as a value that will reliably saturate most
    connections.

### 2.4 Piece Selection

Selecting pieces to download in a good order is very important for good
performance.

#### 2.4.1 Strict Priority

BitTorrent's first policy for piece selection is that once a single sub-piece
has been requested, the remaining sub-pieces from that particular piece are
requested before sub-pieces from any other piece. This will be good for getting
complete pieces as quickly as possible.

#### 2.4.2 Rarest First

When selecting which piece to start downloading next, peers generally download
pieces which the fewest of their own peers have first, a technique referred as
"rarest first".  This technique does a good job of making sure that peers have
pieces which all of their peers want, so uploading can be done when wanted. It
also makes sure that pieces which are more common are left for later, so the
likelihood that a peer which currently is offering upload will later not have
anything of interest is reduced.

#### 2.4.3 Random First Piece

An exception to rarest first is when downloading starts. At that time, the peer
has nothing to upload, so it's important to get a complete piece as quickly as
possible. Rare pieces are generally present on one peer, so they would be
downloaded slower than pieces which are present on multiple peers for which it
is possible to download sub-pieces from different places. Until the first
complete piece is assembled, pieces to download are selected at random and then
strategy changes to rarest first.

#### 2.4.4 Endgame Mode

Closer to the end of download, a peer with very slow transfer rates may delay
download's finish.  To keep that from happening, once all sub-pieces which peer
doesn't have are actively being requested it sends requests for all sub-pieces
to all peers. Cancels are sent for sub-pieces which arrive to keep to much
bandwidth from being wasted on redundant sends.

## 3 Choking Algorithms

To cooperate peers upload, and to not cooperate they 'choke' peers. Choking is a
temporary refusal to upload; it stops uploading but downloading can still happen
and the connection doesn't need to be renegotiated when choking stops.  A good
choking algorithm should utilize all available resources, provide reasonably
consistent download rates for everyone, and be somewhat resistant to peers only
downloading and not uploading.

### 3.2 BitTorrent's Choking Algortihm

Each BitTorrent peer always unchokes a fixed number of other peers (default is
four), so the issue becomes which peers to unchoke. Decisions as to which peers
to unchoke are based strictly on current download rate. Calculating current
download rate meaningfully is a surprisingly difficult problem; the current
implementation essentially uses a rolling 20-second average.  BitTorrent peers
recalculate who they want to choke once every ten seconds, and then leave the
situation as is until the next ten seconds period is up.

### 3.3 Optimistic Unchoking

Simply uploading to the peers which provide the best download rate would suffer
from having no method of discovering if currently unused connections are better
than the ones being used. To fix this, at all times a BitTorrent peer has a
single 'optimistic unchoke' which is unchoked regardless of the current download
rate from it. Which peer is the optimistic unchoke is rotated every third
rechoke period (30 seconds).

### 3.4 Anti-snubbing

Occasionally a BitTorrent peer will be choked by all peers which it was formerly
downloading from.  In such cases it will usually continue to get poor download
rates until the optimistic unchoke finds better peers. Therefore, if over a
minute goes by without getting a single piece from a particular peer, BitTorrent
assumes it is 'snubbed' by that peer and doesn't upload to it except as an
optimistic unchoke.

### 3.5 Upload Only

Once a peer is done downloading, it no longer has useful download rates to
decide which peers to upload to. The current implementation then switches to
preferring peers which it has better upload rates to, which does a decent job of
utilizing all available upload capacity and preferring peers which no one else
happens to be uploading to at the moment.
