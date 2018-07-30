def createBadge(ipfsurl)
  date = Time.new
  ipfsurl = ipfsurl
  certuid = SecureRandom.uuid
  maapubkey = "mtr98kany9G1XYNU74pRnfBQmaCg2FZLmc"
  criteria = "Meets the standards of a critical edition; judged by the MAA as equal in quality to the kinds of editions that appear in the MAA printed editions series or scholarly articles that appear the MAA journal 'Speculum'."
  badgeImage = "http://dll-review-registry.scta.info/maa-badge-working.svg"
  issuerImage = "https://pbs.twimg.com/profile_images/1534408703/maa_symbol_small_400x400.png"
  certificate = {
    "@context": "https://w3id.org/openbadges/v2",
    "id": "urn:uuid:#{certuid}",
    "type": "Assertion",
    "recipient": {
      "type": "url",
      "identity": "http://gateway.scta.info/ipfs/#{ipfsurl}"
    },
    "issuedOn": date,
    "verification": {
      "type": "signedBadge",
      "publicKey": "http://dll-review-registry.scta.info/maa-pub.asc"
    },
    "badge": {
      "image": badgeImage,
      "issuer": {
        "id": "https://www.medievalacademy.org/",
        "image": issuerImage,
        "type": "Profile",
        "name": "Medieval Academy of America",
        "email": "info@themedievalacademy.org",
        "url": "https://www.medievalacademy.org/"
      },
      "criteria": {
        "narrative": criteria
      }
    }
  }

  return JSON.pretty_generate(certificate)

end
def createBadgeOld(ipfsurl)
  date = Time.new
  ipfsurl = ipfsurl
  certuid = SecureRandom.uuid
  maapubkey = "mtr98kany9G1XYNU74pRnfBQmaCg2FZLmc"
  criteria = "Meets the standards of a critical edition; judged by the MAA as equal in quality to the kinds of editions that appear in the MAA printed editions series or scholarly articles that appear the MAA journal 'Speculum'."
  badgeImage = "http://dll-review-registry.scta.info/maa-badge-working.svg"
  issuerImage = "http://dll-review-registry.scta.info/maa-badge-working.svg"
  certificate = {
  "issuedOn": "#{date}",
  "@context": [
    "https://w3id.org/openbadges/v2",
    "https://w3id.org/blockcerts/v2"
  ],
  "verification": {
    "type": [
      "MerkleProofVerification2017",
      "Extension"
    ],
    "publicKey": "ecdsa-koblitz-pubkey:#{maapubkey}"
  },
  "id": "urn:uuid:#{certuid}",
  "recipient": {
    "hashed": false,
    "identity": "#{ipfsurl}",
    "type": "url"
  },
  "type": "Assertion",
  "badge": {
    "image": badgeImage,
    "issuer": {
      "image": issuerImage ,
      "revocationList": "https://www.blockcerts.org/samples/2.0/revocation-list-testnet.json",
      "id": "https://www.blockcerts.org/samples/2.0/issuer-testnet.json",
      "type": "Profile",
      "name": "Medieval Academy of America",
      "email": "admin@maa.org",
      "url": "https://www.maa.org"
    },
    "criteria": {"narrative": criteria},
    "signatureLines": [{
      "image": "",
      "type": [
        "SignatureLine",
        "Extension"
      ],
      "name": "Your signature",
      "jobTitle": "University Issuer"
    }],
    "description": "Peer Review MAA Gold",
    "id": "MAA_Gold",
    "type": "BadgeClass",
    "name": "MAA Gold"
  }
}
return JSON.pretty_generate(certificate)

end
