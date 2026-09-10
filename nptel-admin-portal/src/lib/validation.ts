export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

export function validatePassword(password: string): boolean {
  return password.length >= 8
}

export function validateForm(formData: Record<string, any>): string[] {
  const errors: string[] = []
  
  if (!formData.email) {
    errors.push('Email is required')
  } else if (!validateEmail(formData.email)) {
    errors.push('Invalid email format')
  }
  
  if (!formData.password) {
    errors.push('Password is required')
  } else if (!validatePassword(formData.password)) {
    errors.push('Password must be at least 8 characters')
  }
  
  return errors
}
