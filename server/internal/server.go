package internal

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"net"
	"strings"
	"sync"
	"time"
)

func StartServer() {

	startUDPListener()
	startGinServer()
}

func startUDPListener() {
	addr := &net.UDPAddr{
		IP:   net.IPv4(0, 0, 0, 0),
		Port: 12345,
		Zone: "",
	}
	conn, err := net.ListenUDP("udp", addr)
	if err != nil {
		return
	}
	defer func(conn *net.UDPConn) {
		err := conn.Close()
		if err != nil {
			println(err)
		}
	}(conn)

	remoteConns := new(sync.Map)

	for {
		buf := make([]byte, 1024)
		n, remoteAddr, err := conn.ReadFrom(buf)
		if err != nil {
			continue
		}

		// Process the received message
		handleMessage(buf[:n])

		if _, ok := remoteConns.Load(remoteAddr.String()); !ok {
			remoteConns.Store(remoteAddr.String(), &remoteAddr)
		}

		// Broadcast message to all connected clients
		go func() {
			remoteConns.Range(func(key, value interface{}) bool {
				if _, err := conn.WriteTo(buf[:n], *value.(*net.Addr)); err != nil {
					remoteConns.Delete(key)

					return true
				}

				return true
			})
		}()
	}
}

func handleMessage(msg []byte) {
	// Handle the received message here

	now := time.Now()
	message := string(msg)
	fmt.Println("Received message:", message)

	version := strings.Split(message, "&&")

	if len(version) > 0 {
		if version[0] == "v1" {
			handleV1Message(version, now)
		} else {
			println("Unknown version of the message received. Ignoring it.")
		}
	} else {
		println("Message broken")
	}

}

func handleV1Message(values []string, now time.Time) {
	message := values[1]
	timestamp := values[2]
	// parse utc iso 8601 string to datetime
	datetime, err := time.Parse(time.RFC3339, timestamp)

	if err != nil {
		println("Error parsing datetime:", err.Error())
		return
	}

	// substract now from the received datetime
	diff := now.Sub(datetime)

	/// print in ms
	fmt.Println("Message:", message)
	fmt.Printf("Delay: %d microseconds\n\n", diff.Microseconds())

}

func startGinServer() {
	s := gin.Default()
	err := s.Run("localhost:" + "8085")

	if err != nil {
		println("Something went wrong with running the server")
		println(err)
		return
	}
}
