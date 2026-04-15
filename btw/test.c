// Understand this code as well

int multiply(int x, int y) {
    return x * y;
}

int square(int n) {
    int result = multiply(n, n);
    return result;
}

int main(void) {
    int val = square(5);
    return val;
}
