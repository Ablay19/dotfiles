  },
  "settings": {
    "executionOrder": "v1"
  },
  "active": false
}'
curl -X POST "https://n8n-49ap.onrender.com/rest/workflows"   -H "Content-Type: application/json"   -H "X-N8N-API-KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NGE0NmRmMy01YzM0LTQ1NWQtYmU0Zi0xMDZmY2Q1Zjg3YjAiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzYxOTgzNjI3fQ.hBx9dK_Bd-egZYK2R0LZbaz48xJM34dyjsfjXpetqBA"   -d '{
  "name": "Extract RimNow News Details",
  "nodes": [
    {
      "parameters": {
        "url": "https://rimnow.com",
        "responseFormat": "string"
      },
      "id": "1",
      "name": "Fetch RimNow Page",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.3,
      "position": [-500, 0]
    },
    {
      "parameters": {
        "html": "={{ $json[\"body\"] }}",
        "cssSelector": "div#rss_block li a, ul.item_rss li a, h3.news-title a",
        "returnArray": true
      },
      "id": "2",
      "name": "Extract Links",
      "type": "n8n-nodes-base.htmlExtract",
      "typeVersion": 1,
      "position": [-300, 0]
    },
    {
      "parameters": {
        "functionCode": "const links = $json[\"htmlExtract\"] || [];\nconst articles = links.map(a => ({\n  title: a.text?.trim() || \"Untitled\",\n  link: a.href?.startsWith(\"http\") ? a.href : `https://rimnow.com/${a.href.replace(/^\\/+/,'')}`\n}));\nconst unique = Array.from(new Map(articles.map(a => [a.link, a])).values());\nreturn unique.slice(0,10);"
      },
      "id": "3",
      "name": "Format Links",
      "type": "n8n-nodes-base.function",
      "typeVersion": 2,
      "position": [-100, 0]
    },
    {
      "parameters": {
        "batchSize": 1
      },
      "id": "4",
      "name": "Split In Batches",
      "type": "n8n-nodes-base.splitInBatches",
      "typeVersion": 1,
      "position": [100, 0]
    },
    {
      "parameters": {
        "url": "={{ $json[\"link\"] }}",
        "responseFormat": "string"
      },
      "id": "5",
      "name": "Fetch Article",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.3,
      "position": [300, 0]
    },
    {
      "parameters": {
        "html": "={{ $json[\"body\"] }}",
        "cssSelector": "div.article-content p, div.post-content p, article p",
        "returnArray": true
      },
      "id": "6",
      "name": "Extract Description",
      "type": "n8n-nodes-base.htmlExtract",
      "typeVersion": 1,
      "position": [500, 0]
    },
    {
      "parameters": {
        "functionCode": "const paragraphs = $json[\"htmlExtract\"] || [];\nconst summary = paragraphs.map(p => p.text.trim()).filter(Boolean).slice(0,3).join(' ');\nreturn [{\n  title: $json[\"title\"],\n  link: $json[\"link\"],\n  summary,\n  scraped_at: new Date().toISOString()\n}];"
      },
      "id": "7",
      "name": "Assemble Result",
      "type": "n8n-nodes-base.function",
      "typeVersion": 2,
      "position": [700, 0]
    },
    {
      "parameters": {
        "mode": "waitAll"
      },
      "id": "8",
      "name": "Merge Results",
      "type": "n8n-nodes-base.merge",
      "typeVersion": 2,
      "position": [900, 0]
    }
  ],
  "connections": {
    "Fetch RimNow Page": { "main": [ [ { "node": "Extract Links", "type": "main", "index": 0 } ] ] },
    "Extract Links": { "main": [ [ { "node": "Format Links", "type": "main", "index": 0 } ] ] },
    "Format Links": { "main": [ [ { "node": "Split In Batches", "type": "main", "index": 0 } ] ] },
    "Split In Batches": { "main": [ [ { "node": "Fetch Article", "type": "main", "index": 0 } ] ] },
    "Fetch Article": { "main": [ [ { "node": "Extract Description", "type": "main", "index": 0 } ] ] },
    "Extract Description": { "main": [ [ { "node": "Assemble Result", "type": "main", "index": 0 } ] ] },
    "Assemble Result": { "main": [ [ { "node": "Merge Results", "type": "main", "index": 0 } ] ] }
  },
  "settings": {
    "executionOrder": "v1"
  },
  "active": false
}'
pkg install busybox 
vi serv
chmod +x serv 
./serv 
pkg uninstall busybox 
c
nc
pkg install netcat-openbsd
./serv 
ls
vi response_pipe 
curl -X POST "https://n8n-49ap.onrender.com/api/v1/workflows"   -H "X-N8N-API-KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NGE0NmRmMy01YzM0LTQ1NWQtYmU0Zi0xMDZmY2Q1Zjg3YjAiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzYxOTgzNjI3fQ.hBx9dK_Bd-egZYK2R0LZbaz48xJM34dyjsfjXpetqBA"   -H "Content-Type: application/json"   -d '{
  "name": "News_Bot_Fixed",
  "active": true,
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [
            {
              "field": "cronExpression",
              "expression": "*/15 * * * *"
            }
          ]
        }
      },
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1.2,
      "position": [260, 340],
      "id": "schedule-trigger",
      "name": "Schedule Trigger"
    },
    {
      "parameters": {
        "url": "https://www.rimnow.com",
        "options": {}
      },
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [480, 340],
      "id": "http-request",
      "name": "Fetch RimNow Website"
    },
    {
      "parameters": {
        "jsCode": "// Parse HTML and extract news items\nconst cheerio = require(\"cheerio\");\nconst html = $json.body;\nconst $ = cheerio.load(html);\nconst newsItems = [];\n\n// Try multiple selectors to find news items\n$(\"div#rss_block a, ul.item_rss a, .news-item a, article a, .post-title a\").each((i, elem) => {\n  if (i >= 10) return false; // Limit to 10 items\n  \n  const title = $(elem).text().trim();\n  let link = $(elem).attr(\"href\");\n  \n  if (title && link && title.length > 10) {\n    // Convert relative URLs to absolute\n    if (link.startsWith(\"/\")) {\n      link = \"https://rimnow.com\" + link;\n    }\n    \n    // Avoid duplicates\n    if (!newsItems.find(item => item.link === link)) {\n      newsItems.push({\n        title: title,\n        link: link,\n        scraped_at: new Date().toISOString()\n      });\n    }\n  }\n});\n\n// If no items found with specific selectors, try more general approach\nif (newsItems.length === 0) {\n  $(\"a\").each((i, elem) => {\n    if (i >= 15) return false;\n    \n    const title = $(elem).text().trim();\n    let link = $(elem).attr(\"href\");\n    \n    if (title && link && title.length > 20 && title.length < 200 && \n        (link.includes(\"/news/\") || link.includes(\"/article/\") || link.includes(\"/202\"))) {\n      if (link.startsWith(\"/\")) {\n        link = \"https://rimnow.com\" + link;\n      }\n      \n      if (!newsItems.find(item => item.link === link)) {\n        newsItems.push({\n          title: title,\n          link: link,\n          scraped_at: new Date().toISOString()\n        });\n      }\n    }\n  });\n}\n\nreturn {\n  json: {\n    news: newsItems.slice(0, 8) // Limit to 8 items max\n  }\n};"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [680, 340],
      "id": "parse-html",
      "name": "Parse HTML Content"
    },
    {
      "parameters": {
        "jsCode": "const newsItems = $json.news || [];\n\nif (newsItems.length === 0) {\n  return [{\n    json: {\n      message: \"❌ No news articles found on RimNow today.\",\n      chunkIndex: 1,\n      totalChunks: 1\n    }\n  }];\n}\n\nconst MAX_MESSAGE_LENGTH = 4000;\nconst chunks = [];\nlet currentChunk = [];\nlet currentLength = 0;\n\n// Split into chunks that fit Telegram limits\nnewsItems.forEach((item, index) => {\n  const itemNumber = index + 1;\n  const itemText = `${itemNumber}. [${item.title}](${item.link})\\n`;\n  const itemLength = itemText.length;\n  \n  if (currentLength + itemLength > MAX_MESSAGE_LENGTH && currentChunk.length > 0) {\n    chunks.push([...currentChunk]);\n    currentChunk = [item];\n    currentLength = itemLength;\n  } else {\n    currentChunk.push(item);\n    currentLength += itemLength;\n  }\n});\n\nif (currentChunk.length > 0) {\n  chunks.push(currentChunk);\n}\n\n// Create message chunks\nconst outputs = chunks.map((chunk, index) => {\n  const chunkNumber = index + 1;\n  const totalChunks = chunks.length;\n  \n  let message = `📰 *RimNow News Update* `;\n  if (totalChunks > 1) {\n    message += `(Part ${chunkNumber}/${totalChunks})`;\n  }\n  message += `\\n\\n`;\n  \n  chunk.forEach((item, itemIndex) => {\n    const globalIndex = chunks.slice(0, index).reduce((sum, c) => sum + c.length, 0) + itemIndex + 1;\n    message += `${globalIndex}. [${item.title}](${item.link})\\n\\n`;\n  });\n  \n  if (chunkNumber === totalChunks) {\n    message += `_${newsItems.length} articles fetched at ${new Date().toLocaleTimeString()}_`;\n  }\n  \n  return {\n    json: {\n      message: message,\n      chunkIndex: chunkNumber,\n      totalChunks: totalChunks,\n      newsChunk: chunk\n    }\n  };\n});\n\nreturn outputs;"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [880, 340],
      "id": "split-messages",
      "name": "Split Messages for Telegram"
    },
    {
      "parameters": {
        "chatId": "8246777798",
        "text": "={{ $json.message }}",
        "parseMode": "Markdown",
        "additionalFields": {}
      },
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [1080, 340],
      "id": "telegram-send",
      "name": "Send to Telegram",
      "credentials": {
        "telegramApi": "r4438a2TaFkebFn1"
      }
    }
  ],
  "connections": {
    "Schedule Trigger": {
      "main": [
        [
          {
            "node": "Fetch RimNow Website",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Fetch RimNow Website": {
      "main": [
        [
          {
            "node": "Parse HTML Content",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Parse HTML Content": {
      "main": [
        [
          {
            "node": "Split Messages for Telegram",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Split Messages for Telegram": {
      "main": [
        [
          {
            "node": "Send to Telegram",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "settings": {
    "executionOrder": "v1"
  }
}'
vi .bash_history 
curl -X POST "https://n8n-49ap.onrender.com/api/v1/workflows"   -H "X-N8N-API-KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NGE0NmRmMy01YzM0LTQ1NWQtYmU0Zi0xMDZmY2Q1Zjg3YjAiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzYxOTgzNjI3fQ.hBx9dK_Bd-egZYK2R0LZbaz48xJM34dyjsfjXpetqBA"   -H "Content-Type: application/json"   -d '{
  "name": "News_Bot_Fixed",
  "active": true,
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [
            {
              "field": "cronExpression",
              "expression": "*/15 * * * *"
            }
          ]
        }
      },
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1.2,
      "position": [260, 340],
      "id": "schedule-trigger",
      "name": "Schedule Trigger"
    },
    {
      "parameters": {
        "url": "https://www.rimnow.com",
        "options": {}
      },
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [480, 340],
      "id": "http-request",
      "name": "Fetch RimNow Website"
    },
    {
      "parameters": {
        "jsCode": "// Parse HTML and extract news items\nconst cheerio = require(\"cheerio\");\nconst html = $json.body;\nconst $ = cheerio.load(html);\nconst newsItems = [];\n\n// Try multiple selectors to find news items\n$(\"div#rss_block a, ul.item_rss a, .news-item a, article a, .post-title a\").each((i, elem) => {\n  if (i >= 10) return false; // Limit to 10 items\n  \n  const title = $(elem).text().trim();\n  let link = $(elem).attr(\"href\");\n  \n  if (title && link && title.length > 10) {\n    // Convert relative URLs to absolute\n    if (link.startsWith(\"/\")) {\n      link = \"https://rimnow.com\" + link;\n    }\n    \n    // Avoid duplicates\n    if (!newsItems.find(item => item.link === link)) {\n      newsItems.push({\n        title: title,\n        link: link,\n        scraped_at: new Date().toISOString()\n      });\n    }\n  }\n});\n\n// If no items found with specific selectors, try more general approach\nif (newsItems.length === 0) {\n  $(\"a\").each((i, elem) => {\n    if (i >= 15) return false;\n    \n    const title = $(elem).text().trim();\n    let link = $(elem).attr(\"href\");\n    \n    if (title && link && title.length > 20 && title.length < 200 && \n        (link.includes(\"/news/\") || link.includes(\"/article/\") || link.includes(\"/202\"))) {\n      if (link.startsWith(\"/\")) {\n        link = \"https://rimnow.com\" + link;\n      }\n      \n      if (!newsItems.find(item => item.link === link)) {\n        newsItems.push({\n          title: title,\n          link: link,\n          scraped_at: new Date().toISOString()\n        });\n      }\n    }\n  });\n}\n\nreturn {\n  json: {\n    news: newsItems.slice(0, 8) // Limit to 8 items max\n  }\n};"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [680, 340],
      "id": "parse-html",
      "name": "Parse HTML Content"
    },
    {
      "parameters": {
        "jsCode": "const newsItems = $json.news || [];\n\nif (newsItems.length === 0) {\n  return [{\n    json: {\n      message: \"❌ No news articles found on RimNow today.\",\n      chunkIndex: 1,\n      totalChunks: 1\n    }\n  }];\n}\n\nconst MAX_MESSAGE_LENGTH = 4000;\nconst chunks = [];\nlet currentChunk = [];\nlet currentLength = 0;\n\n// Split into chunks that fit Telegram limits\nnewsItems.forEach((item, index) => {\n  const itemNumber = index + 1;\n  const itemText = `${itemNumber}. [${item.title}](${item.link})\\n`;\n  const itemLength = itemText.length;\n  \n  if (currentLength + itemLength > MAX_MESSAGE_LENGTH && currentChunk.length > 0) {\n    chunks.push([...currentChunk]);\n    currentChunk = [item];\n    currentLength = itemLength;\n  } else {\n    currentChunk.push(item);\n    currentLength += itemLength;\n  }\n});\n\nif (currentChunk.length > 0) {\n  chunks.push(currentChunk);\n}\n\n// Create message chunks\nconst outputs = chunks.map((chunk, index) => {\n  const chunkNumber = index + 1;\n  const totalChunks = chunks.length;\n  \n  let message = `📰 *RimNow News Update* `;\n  if (totalChunks > 1) {\n    message += `(Part ${chunkNumber}/${totalChunks})`;\n  }\n  message += `\\n\\n`;\n  \n  chunk.forEach((item, itemIndex) => {\n    const globalIndex = chunks.slice(0, index).reduce((sum, c) => sum + c.length, 0) + itemIndex + 1;\n    message += `${globalIndex}. [${item.title}](${item.link})\\n\\n`;\n  });\n  \n  if (chunkNumber === totalChunks) {\n    message += `_${newsItems.length} articles fetched at ${new Date().toLocaleTimeString()}_`;\n  }\n  \n  return {\n    json: {\n      message: message,\n      chunkIndex: chunkNumber,\n      totalChunks: totalChunks,\n      newsChunk: chunk\n    }\n  };\n});\n\nreturn outputs;"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [880, 340],
      "id": "split-messages",
      "name": "Split Messages for Telegram"
    },
    {
      "parameters": {
        "chatId": "8246777798",
        "text": "={{ $json.message }}",
        "parseMode": "Markdown",
        "additionalFields": {}
      },
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [1080, 340],
      "id": "telegram-send",
      "name": "Send to Telegram",
      "credentials": {
        "telegramApi": "r4438a2TaFkebFn1"
      }
    }
  ],
  "connections": {
    "Schedule Trigger": {
      "main": [
        [
          {
            "node": "Fetch RimNow Website",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Fetch RimNow Website": {
      "main": [
        [
          {
            "node": "Parse HTML Content",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Parse HTML Content": {
      "main": [
        [
          {
            "node": "Split Messages for Telegram",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Split Messages for Telegram": {
      "main": [
        [
          {
            "node": "Send to Telegram",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "settings": {
    "executionOrder": "v1"
  }
}'
[200~curl -X POST "https://n8n-49ap.onrender.com/api/v1/workflows"   -H "X-N8N-API-KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NGE0NmRmMy01YzM0LTQ1NWQtYmU0Zi0xMDZmY2Q1Zjg3YjAiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzYxOTgzNjI3fQ.hBx9dK_Bd-egZYK2R0LZbaz48xJM34dyjsfjXpetqBA"   -H "Content-Type: application/json"   -d '{
  "name": "News_Bot_Fixed",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [
            {
              "field": "cronExpression",
              "expression": "*/15 * * * *"
            }
          ]
        }
      },
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1.2,
      "position": [260, 340],
      "id": "schedule-trigger",
      "name": "Schedule Trigger"
    },
    {
      "parameters": {
        "url": "https://www.rimnow.com",
        "options": {}
      },
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [480, 340],
      "id": "http-request",
      "name": "Fetch RimNow Website"
    },
    {
      "parameters": {
        "jsCode": "// Parse HTML and extract news items\nconst cheerio = require(\"cheerio\");\nconst html = $json.body;\nconst $ = cheerio.load(html);\nconst newsItems = [];\n\n// Try multiple selectors to find news items\n$(\"div#rss_block a, ul.item_rss a, .news-item a, article a, .post-title a\").each((i, elem) => {\n  if (i >= 10) return false; // Limit to 10 items\n  \n  const title = $(elem).text().trim();\n  let link = $(elem).attr(\"href\");\n  \n  if (title && link && title.length > 10) {\n    // Convert relative URLs to absolute\n    if (link.startsWith(\"/\")) {\n      link = \"https://rimnow.com\" + link;\n    }\n    \n    // Avoid duplicates\n    if (!newsItems.find(item => item.link === link)) {\n      newsItems.push({\n        title: title,\n        link: link,\n        scraped_at: new Date().toISOString()\n      });\n    }\n  }\n});\n\n// If no items found with specific selectors, try more general approach\nif (newsItems.length === 0) {\n  $(\"a\").each((i, elem) => {\n    if (i >= 15) return false;\n    \n    const title = $(elem).text().trim();\n    let link = $(elem).attr(\"href\");\n    \n    if (title && link && title.length > 20 && title.length < 200 && \n        (link.includes(\"/news/\") || link.includes(\"/article/\") || link.includes(\"/202\"))) {\n      if (link.startsWith(\"/\")) {\n        link = \"https://rimnow.com\" + link;\n      }\n      \n      if (!newsItems.find(item => item.link === link)) {\n        newsItems.push({\n          title: title,\n          link: link,\n          scraped_at: new Date().toISOString()\n        });\n      }\n    }\n  });\n}\n\nreturn {\n  json: {\n    news: newsItems.slice(0, 8) // Limit to 8 items max\n  }\n};"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [680, 340],
      "id": "parse-html",
      "name": "Parse HTML Content"
    },
    {
      "parameters": {
        "jsCode": "const newsItems = $json.news || [];\n\nif (newsItems.length === 0) {\n  return [{\n    json: {\n      message: \"❌ No news articles found on RimNow today.\",\n      chunkIndex: 1,\n      totalChunks: 1\n    }\n  }];\n}\n\nconst MAX_MESSAGE_LENGTH = 4000;\nconst chunks = [];\nlet currentChunk = [];\nlet currentLength = 0;\n\n// Split into chunks that fit Telegram limits\nnewsItems.forEach((item, index) => {\n  const itemNumber = index + 1;\n  const itemText = `${itemNumber}. [${item.title}](${item.link})\\n`;\n  const itemLength = itemText.length;\n  \n  if (currentLength + itemLength > MAX_MESSAGE_LENGTH && currentChunk.length > 0) {\n    chunks.push([...currentChunk]);\n    currentChunk = [item];\n    currentLength = itemLength;\n  } else {\n    currentChunk.push(item);\n    currentLength += itemLength;\n  }\n});\n\nif (currentChunk.length > 0) {\n  chunks.push(currentChunk);\n}\n\n// Create message chunks\nconst outputs = chunks.map((chunk, index) => {\n  const chunkNumber = index + 1;\n  const totalChunks = chunks.length;\n  \n  let message = `📰 *RimNow News Update* `;\n  if (totalChunks > 1) {\n    message += `(Part ${chunkNumber}/${totalChunks})`;\n  }\n  message += `\\n\\n`;\n  \n  chunk.forEach((item, itemIndex) => {\n    const globalIndex = chunks.slice(0, index).reduce((sum, c) => sum + c.length, 0) + itemIndex + 1;\n    message += `${globalIndex}. [${item.title}](${item.link})\\n\\n`;\n  });\n  \n  if (chunkNumber === totalChunks) {\n    message += `_${newsItems.length} articles fetched at ${new Date().toLocaleTimeString()}_`;\n  }\n  \n  return {\n    json: {\n      message: message,\n      chunkIndex: chunkNumber,\n      totalChunks: totalChunks,\n      newsChunk: chunk\n    }\n  };\n});\n\nreturn outputs;"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [880, 340],
      "id": "split-messages",
      "name": "Split Messages for Telegram"
    },
    {
      "parameters": {
        "chatId": "8246777798",
        "text": "={{ $json.message }}",
        "parseMode": "Markdown",
        "additionalFields": {}
      },
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [1080, 340],
      "id": "telegram-send",
      "name": "Send to Telegram",
      "credentials": {
        "telegramApi": "r4438a2TaFkebFn1"
      }
    }
  ],
  "connections": {
    "Schedule Trigger": {
      "main": [
        [
          {
            "node": "Fetch RimNow Website",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Fetch RimNow Website": {
      "main": [
        [
          {
            "node": "Parse HTML Content",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Parse HTML Content": {
      "main": [
        [
          {
            "node": "Split Messages for Telegram",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Split Messages for Telegram": {
      "main": [
        [
          {
            "node": "Send to Telegram",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "settings": {
    "executionOrder": "v1"
  }
}'~
vi scripts/rimnow.sh 
./scripts/rimnow.sh 
/data/data/com.termux/files/usr/bin/ssh -t -p 6000     -i /data/data/com.termux/files/home/.ssh/google_compute_engine     -o StrictHostKeyChecking=no     -L 11434:127.0.0.1:11434     abdoullahelvogani@35.187.5.159     -- DEVSHELL_PROJECT_ID=beaming-gadget-468214-s8 'bash -l'
./google-cloud-sdk/bin/gcloud cloud-shell reset
./google-cloud-sdk/bin/gcloud 
/data/data/com.termux/files/usr/bin/ssh -t -p 6000     -i /data/data/com.termux/files/home/.ssh/google_compute_engine     -o StrictHostKeyChecking=no     -L 11434:127.0.0.1:11434     abdoullahelvogani@35.187.5.159     -- DEVSHELL_PROJECT_ID=beaming-gadget-468214-s8 'bash -l'
http://localhost:11434/api
xh http://localhost:11434/api
/data/data/com.termux/files/usr/bin/ssh -t -p 6000     -i /data/data/com.termux/files/home/.ssh/google_compute_engine     -o StrictHostKeyChecking=no     -L 11434:127.0.0.1:11434     abdoullahelvogani@35.187.5.159     -- DEVSHELL_PROJECT_ID=beaming-gadget-468214-s8 'bash -l'
./google-cloud-sdk/bin/gcloud cloud-shell ssh --dry-run 
/data/data/com.termux/files/usr/bin/ssh -t -p 6000     -i /data/data/com.termux/files/home/.ssh/google_compute_engine     -o StrictHostKeyChecking=no     -L 11434:127.0.0.1:11434     abdoullahelvogani@35.187.5.159     -- DEVSHELL_PROJECT_ID=beaming-gadget-468214-s8 'bash -l'
./bin/opencode 
$(npm root -g)/opencode-linux-arm64/bin/opencode
mkdir -p ~/opencode
cd ~/opencode
npm pack opencode-linux-arm64
tar -xzf opencode-linux-arm64-*.tgz
node package/bin/opencode
..
export BUN_INSTALL="$HOME/.bun"
bun
vi .bun/bin/bun 
