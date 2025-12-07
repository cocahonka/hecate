package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"flag"
	"fmt"
	"os"
)

func main() {
	mode := flag.String("mode", "gen", "Mode: gen (generate keys) or sign (sign message)")
	privKeyFile := flag.String("key", "priv.pem", "Private key file")
	msg := flag.String("msg", "", "Message to sign (Base64Url encoded)")
	flag.Parse()

	if *mode == "gen" {
		priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
		if err != nil {
			panic(err)
		}

		// Save Private
		privBytes, _ := x509.MarshalECPrivateKey(priv)
		privPem := pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: privBytes})
		os.WriteFile("priv.pem", privPem, 0600)

		// Print Public
		pubBytes, _ := x509.MarshalPKIXPublicKey(&priv.PublicKey)
		pubPem := pem.EncodeToMemory(&pem.Block{Type: "PUBLIC KEY", Bytes: pubBytes})
		fmt.Println(string(pubPem))

	} else if *mode == "sign" {
		privPem, err := os.ReadFile(*privKeyFile)
		if err != nil {
			panic(err)
		}
		block, _ := pem.Decode(privPem)
		priv, err := x509.ParseECPrivateKey(block.Bytes)
		if err != nil {
			panic(err)
		}

		// Server decodes challenge from Base64Url
		challengeBytes, err := base64.RawURLEncoding.DecodeString(*msg)
		if err != nil {
			panic(fmt.Sprintf("Failed to decode challenge: %v", err))
		}

		hash := sha256.Sum256(challengeBytes)
		
		// Sign with ASN.1 format
		signature, err := ecdsa.SignASN1(rand.Reader, priv, hash[:])
		if err != nil {
			panic(err)
		}

		// Encode signature to Base64Url
		fmt.Print(base64.RawURLEncoding.EncodeToString(signature))
	}
}