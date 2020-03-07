## Game Installation

Additional to the project requirements we deployed our project to a web server, hence there are two ways of playing our Blackjack game:

1. Online on the web server using this URL: http://blackjack.brzoza.me
2. Locally using a BaseX Server on your own Computer

We recommend the usage of Google Chrome as Browser. Our game is compatible with Google Chrome and Firefox on Windows and macOS, but it is optimized for Google Chrome only. (Please do not use Internet Explorer or Safari as it can result to rendering issues).

## Requirements
1. For the first option the only requirement is an IPv4 connection. The server cannot be addressed through IPv6.
2. The second option requires a running BaseX STOMP HTTP server and running BaseX database Server.

## Installation

1. No installation has to be performed to play the game on the web server.
2. To install the BaseX STOMP HTTP sever a few steps have to be made

* Download the complete BaseX program (BaseX931.zip, status March 2020) from their website http://basex.org/download/.
* Download and build the BaseX STOMP packet from the stomp branch in the git repository (https://github.com/BaseXdb/basex/tree/stomp) using Maven.
* Copy the webapp/docbook_blackjack folder into the webapp folder of BaseX.
* Copy the static/docbook_blackjack folder into the webapp/static folder of BaseX.
* Now you can start the BaseX HTTP server.
* The game can be played by calling this link: http://localhost:8984/docbook_blackjack/setup.

The databases are created upon first calling the setup link. Once all databases are created, the setup link will directly redirect to the Lobby. To delete the databases, you have to access them directly on the BaseX database administration interface using this link: http://localhost:8984/dba