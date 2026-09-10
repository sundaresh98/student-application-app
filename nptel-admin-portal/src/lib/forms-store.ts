export interface Form {
  id: string
  title: string
  description?: string
  fields: FormField[]
  responses: FormResponse[]
}

export interface FormField {
  id: string
  type: 'text' | 'email' | 'number' | 'select' | 'checkbox'
  label: string
  required: boolean
  options?: string[]
}

export interface FormResponse {
  id: string
  formId: string
  data: Record<string, any>
  createdAt: Date
}

// In-memory store for development
const formsStore: Map<string, Form> = new Map()

export function getAllForms(): Form[] {
  return Array.from(formsStore.values())
}

export function getFormById(id: string): Form | undefined {
  return formsStore.get(id)
}

export function createForm(form: Form): Form {
  formsStore.set(form.id, form)
  return form
}

export function updateForm(id: string, updates: Partial<Form>): Form | undefined {
  const form = formsStore.get(id)
  if (!form) return undefined
  
  const updated = { ...form, ...updates }
  formsStore.set(id, updated)
  return updated
}

export function deleteForm(id: string): boolean {
  return formsStore.delete(id)
}
