package firebase

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// FirestoreDocument represents a document in Firestore REST API format
type FirestoreDocument struct {
	Name   string                 `json:"name,omitempty"`
	Fields map[string]interface{} `json:"fields"`
}

type FirestoreClient struct {
	ProjectID string
	fb        *FirebaseClient // auth token is read on every request so refreshes are picked up
	client    *http.Client
}

func NewFirestoreClient(fb *FirebaseClient) *FirestoreClient {
	return &FirestoreClient{
		ProjectID: fb.ProjectID,
		fb:        fb,
		client:    http.DefaultClient,
	}
}

func (c *FirestoreClient) authHeader() string {
	return fmt.Sprintf("Bearer %s", c.fb.GetIDToken())
}

// GetDocument retrieves a document from Firestore using REST API
func (c *FirestoreClient) GetDocument(ctx context.Context, path string) (map[string]interface{}, error) {
	url := fmt.Sprintf("https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/%s",
		c.ProjectID, path)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", c.authHeader())
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get document: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode == http.StatusNotFound {
		return nil, nil // Document not found
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("get document failed with status %d: %s", resp.StatusCode, string(body))
	}

	var doc FirestoreDocument
	if err := json.Unmarshal(body, &doc); err != nil {
		return nil, fmt.Errorf("failed to parse document: %w", err)
	}

	return convertFirestoreFields(doc.Fields), nil
}

// CreateDocument creates a new document in Firestore
func (c *FirestoreClient) CreateDocument(ctx context.Context, path string, documentID string, data map[string]interface{}) error {
	url := fmt.Sprintf("https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/%s?documentId=%s",
		c.ProjectID, path, documentID)

	fields := convertToFirestoreFields(data)
	doc := FirestoreDocument{Fields: fields}

	jsonData, err := json.Marshal(doc)
	if err != nil {
		return fmt.Errorf("failed to marshal document: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", c.authHeader())
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to create document: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("create document failed with status %d: %s", resp.StatusCode, string(body))
	}

	return nil
}

// UpdateDocument updates a document in Firestore (using PATCH)
func (c *FirestoreClient) UpdateDocument(ctx context.Context, fullPath string, data map[string]interface{}) error {
	url := fmt.Sprintf("https://firestore.googleapis.com/v1/%s", fullPath)

	fields := convertToFirestoreFields(data)
	doc := FirestoreDocument{Fields: fields}

	jsonData, err := json.Marshal(doc)
	if err != nil {
		return fmt.Errorf("failed to marshal document: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "PATCH", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", c.authHeader())
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to update document: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("update document failed with status %d: %s", resp.StatusCode, string(body))
	}

	return nil
}

// DeleteDocument deletes a document from Firestore
func (c *FirestoreClient) DeleteDocument(ctx context.Context, fullPath string) error {
	url := fmt.Sprintf("https://firestore.googleapis.com/v1/%s", fullPath)

	req, err := http.NewRequestWithContext(ctx, "DELETE", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", c.authHeader())

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to delete document: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("delete document failed with status %d: %s", resp.StatusCode, string(body))
	}

	return nil
}

// DocumentResult holds a Firestore document's ID and its decoded fields.
type DocumentResult struct {
	ID     string
	Fields map[string]interface{}
}

// ListDocumentsWithIDs lists all documents in a collection, returning the
// Firestore document ID alongside the decoded fields.
func (c *FirestoreClient) ListDocumentsWithIDs(ctx context.Context, path string) ([]DocumentResult, error) {
	url := fmt.Sprintf("https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/%s",
		c.ProjectID, path)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", c.authHeader())

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to list documents: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("list documents failed with status %d: %s", resp.StatusCode, string(body))
	}

	var result struct {
		Documents []FirestoreDocument `json:"documents"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse documents: %w", err)
	}

	docs := make([]DocumentResult, 0, len(result.Documents))
	for _, doc := range result.Documents {
		// The Name field is the full resource path; the document ID is the last segment.
		id := doc.Name
		if idx := len(doc.Name) - 1; idx >= 0 {
			for i := len(doc.Name) - 1; i >= 0; i-- {
				if doc.Name[i] == '/' {
					id = doc.Name[i+1:]
					break
				}
			}
		}
		docs = append(docs, DocumentResult{
			ID:     id,
			Fields: convertFirestoreFields(doc.Fields),
		})
	}
	return docs, nil
}

// ListDocuments lists all documents in a collection
func (c *FirestoreClient) ListDocuments(ctx context.Context, path string) ([]map[string]interface{}, error) {
	url := fmt.Sprintf("https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/%s",
		c.ProjectID, path)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", c.authHeader())

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to list documents: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("list documents failed with status %d: %s", resp.StatusCode, string(body))
	}

	var result struct {
		Documents []FirestoreDocument `json:"documents"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse documents: %w", err)
	}

	documents := make([]map[string]interface{}, len(result.Documents))
	for i, doc := range result.Documents {
		documents[i] = convertFirestoreFields(doc.Fields)
	}

	return documents, nil
}

// convertToFirestoreFields converts a map to Firestore REST API field format
func convertToFirestoreFields(data map[string]interface{}) map[string]interface{} {
	fields := make(map[string]interface{})
	for key, value := range data {
		fields[key] = wrapValue(value)
	}
	return fields
}

// wrapValue wraps a value in Firestore REST API format
func wrapValue(value interface{}) map[string]interface{} {
	switch v := value.(type) {
	case string:
		return map[string]interface{}{"stringValue": v}
	case int, int32, int64:
		return map[string]interface{}{"integerValue": fmt.Sprintf("%d", v)}
	case float32, float64:
		return map[string]interface{}{"doubleValue": v}
	case bool:
		return map[string]interface{}{"booleanValue": v}
	case nil:
		return map[string]interface{}{"nullValue": nil}
	case map[string]interface{}:
		return map[string]interface{}{"mapValue": map[string]interface{}{"fields": convertToFirestoreFields(v)}}
	case []interface{}:
		values := make([]interface{}, len(v))
		for i, item := range v {
			values[i] = wrapValue(item)
		}
		return map[string]interface{}{"arrayValue": map[string]interface{}{"values": values}}
	default:
		// Try to marshal as JSON and wrap as string
		jsonBytes, _ := json.Marshal(v)
		return map[string]interface{}{"stringValue": string(jsonBytes)}
	}
}

// convertFirestoreFields converts Firestore REST API fields to a regular map
func convertFirestoreFields(fields map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})
	for key, value := range fields {
		result[key] = unwrapValue(value)
	}
	return result
}

// unwrapValue unwraps a Firestore REST API value
func unwrapValue(value interface{}) interface{} {
	valueMap, ok := value.(map[string]interface{})
	if !ok {
		return value
	}

	if strVal, ok := valueMap["stringValue"]; ok {
		return strVal
	}
	if intVal, ok := valueMap["integerValue"]; ok {
		if intStr, ok := intVal.(string); ok {
			var num int64
			fmt.Sscanf(intStr, "%d", &num)
			return num
		}
		return intVal
	}
	if doubleVal, ok := valueMap["doubleValue"]; ok {
		return doubleVal
	}
	if boolVal, ok := valueMap["booleanValue"]; ok {
		return boolVal
	}
	if _, ok := valueMap["nullValue"]; ok {
		return nil
	}
	if mapVal, ok := valueMap["mapValue"].(map[string]interface{}); ok {
		if mapFields, ok := mapVal["fields"].(map[string]interface{}); ok {
			return convertFirestoreFields(mapFields)
		}
	}
	if arrayVal, ok := valueMap["arrayValue"].(map[string]interface{}); ok {
		// Firestore omits the "values" key for empty arrays.
		values, _ := arrayVal["values"].([]interface{})
		result := make([]interface{}, len(values))
		for i, v := range values {
			result[i] = unwrapValue(v)
		}
		return result
	}

	return value
}
