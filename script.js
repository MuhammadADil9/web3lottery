const url = 'https://eth-sepolia.g.alchemy.com/v2/wsaGf76IODKSlWVJ0pwtTu2XY9yJrkme';
const headers = {
    'Content-Type': 'application/json'
};

const body = JSON.stringify({
    jsonrpc: "2.0",
    method: "alchemy_simulateAssetChanges",
    id: 1,
    params: [
        {
            from: "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8",
            to: "0xc02aaa39b223fe8d050e5c4f27ead9083c756cc2",
            value: "0xDE0B6B3A7640000"
        }
    ]
});

fetch(url, {
    method: 'POST',
    headers: headers,
    body: body
})
.then(response => response.json())
.then(data => console.log(data))
.catch(error => console.error('Error:', error));