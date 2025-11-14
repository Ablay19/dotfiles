#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libxml/HTMLparser.h>
#include <libxml/xpath.h>

typedef struct {
    char *title;
    char **body;
    int body_count;
    char *date;
} Article;

char* extract_text(xmlNode *node) {
    if (!node) return NULL;
    
    xmlChar *content = xmlNodeGetContent(node);
    if (!content) return NULL;
    
    char *result = strdup((char*)content);
    xmlFree(content);
    
    // Trim whitespace
    char *start = result;
    while (*start && (*start == ' ' || *start == '\n' || *start == '\t')) start++;
    
    char *end = start + strlen(start) - 1;
    while (end > start && (*end == ' ' || *end == '\n' || *end == '\t')) end--;
    *(end + 1) = '\0';
    
    char *trimmed = strdup(start);
    free(result);
    return trimmed;
}

xmlXPathObjectPtr get_nodes(xmlDocPtr doc, const char *xpath) {
    xmlXPathContextPtr context = xmlXPathNewContext(doc);
    if (!context) return NULL;
    
    xmlXPathObjectPtr result = xmlXPathEvalExpression((xmlChar*)xpath, context);
    xmlXPathFreeContext(context);
    
    return result;
}

void extract_article(xmlDocPtr doc, Article *article) {
    article->body = NULL;
    article->body_count = 0;
    
    // Extract title
    xmlXPathObjectPtr title_nodes = get_nodes(doc, "//div[@id='title']//h1");
    if (title_nodes && title_nodes->nodesetval && title_nodes->nodesetval->nodeNr > 0) {
        article->title = extract_text(title_nodes->nodesetval->nodeTab[0]);
    }
    xmlXPathFreeObject(title_nodes);
    
    // Extract body paragraphs
    xmlXPathObjectPtr para_nodes = get_nodes(doc, 
        "//div[contains(@class, 'field-name-body')]//p");
    if (para_nodes && para_nodes->nodesetval) {
        int count = para_nodes->nodesetval->nodeNr;
        article->body = malloc(sizeof(char*) * count);
        
        for (int i = 0; i < count; i++) {
            char *text = extract_text(para_nodes->nodesetval->nodeTab[i]);
            if (text && strlen(text) > 0) {
                article->body[article->body_count++] = text;
            }
        }
    }
    xmlXPathFreeObject(para_nodes);
    
    // Extract date
    xmlXPathObjectPtr date_nodes = get_nodes(doc, "//span[@class='date']");
    if (date_nodes && date_nodes->nodesetval && date_nodes->nodesetval->nodeNr > 0) {
        article->date = extract_text(date_nodes->nodesetval->nodeTab[0]);
    }
    xmlXPathFreeObject(date_nodes);
}

void free_article(Article *article) {
    if (article->title) free(article->title);
    if (article->date) free(article->date);
    if (article->body) {
        for (int i = 0; i < article->body_count; i++) {
            free(article->body[i]);
        }
        free(article->body);
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <html_file>\n", argv[0]);
        return 1;
    }
    
    LIBXML_TEST_VERSION
    
    htmlDocPtr doc = htmlReadFile(argv[1], NULL, 
        HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING);
    
    if (!doc) {
        fprintf(stderr, "Error parsing HTML file\n");
        return 1;
    }
    
    Article article = {0};
    extract_article(doc, &article);
    
    printf("Title: %s\n\n", article.title ? article.title : "N/A");
    printf("Date: %s\n\n", article.date ? article.date : "N/A");
    printf("Body:\n");
    
    for (int i = 0; i < article.body_count; i++) {
        printf("%d. %s\n\n", i + 1, article.body[i]);
    }
    
    free_article(&article);
    xmlFreeDoc(doc);
    xmlCleanupParser();
    
    return 0;
}
